import { Router } from 'express';
import { z } from 'zod';

import { encryptToken, exchangeServerAuthCode } from '../lib/googleOAuth';
import { syncJagoForUser } from '../lib/jagoSync';
import { prisma } from '../lib/prisma';
import { requireAuth } from '../middleware/auth';

export const jagoRouter = Router();
jagoRouter.use(requireAuth);

const connectSchema = z.object({
  server_auth_code: z.string().min(1),
});

// No wallet to pick anymore — Bank Jago sync auto-creates and manages its
// own wallet per Kantong (see lib/jagoSync.ts's resolveKantongWallet).
//
// Doesn't wait for the sync to finish before responding — a first-time
// connect can mean scanning years of Gmail history (confirmed against a
// real account: 175 messages), which can comfortably exceed Render's
// request timeout and leave the app hanging or erroring out even though
// the sync itself keeps running fine to completion server-side regardless
// (this happened for real: the request appeared to hang/fail client-side,
// but all 175 messages were correctly imported by the time anyone
// checked). The app's own regular sync cycle (SyncService.syncNow, right
// before every /sync/pull) picks up whatever this leaves behind moments
// later, so there's nothing to actually wait for here.
jagoRouter.post('/connect', async (req, res) => {
  const parsed = connectSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid request body', details: parsed.error.flatten() });
    return;
  }
  const userId = req.userId;

  let tokens;
  try {
    tokens = await exchangeServerAuthCode(parsed.data.server_auth_code);
  } catch (err) {
    res.status(400).json({ error: err instanceof Error ? err.message : 'Failed to exchange Google auth code' });
    return;
  }

  const existing = await prisma.user.findUnique({ where: { id: userId }, select: { jagoHistoryId: true } });

  await prisma.user.update({
    where: { id: userId },
    data: {
      jagoRefreshToken: encryptToken(tokens.refreshToken),
      // Only ever null on a genuine first-time connect (triggering a full
      // historical scan) — preserved on a reconnect so re-pressing
      // "Hubungkan Gmail" doesn't force a wasteful, slow full rescan of
      // an account that's already caught up.
      jagoHistoryId: existing?.jagoHistoryId ?? null,
      jagoConnectedAt: new Date(),
    },
  });

  syncJagoForUser(userId).catch(() => {});
  res.json({ connected: true, imported: 0 });
});

jagoRouter.delete('/connect', async (req, res) => {
  await prisma.user.update({
    where: { id: req.userId },
    data: { jagoRefreshToken: null, jagoHistoryId: null, jagoConnectedAt: null },
  });
  res.json({ connected: false });
});

jagoRouter.get('/status', async (req, res) => {
  const user = await prisma.user.findUnique({ where: { id: req.userId } });
  if (!user) {
    res.status(404).json({ error: 'User not found' });
    return;
  }
  res.json({
    connected: Boolean(user.jagoRefreshToken),
    connected_at: user.jagoConnectedAt?.toISOString() ?? null,
  });
});

// Re-triggered on every regular app sync cycle (see Flutter
// sync_service.dart), in addition to any manual "Sync sekarang" button —
// a no-op (200, not an error) for users who never connected Jago, so it's
// safe to call unconditionally.
jagoRouter.post('/sync', async (req, res) => {
  try {
    const result = await syncJagoForUser(req.userId);
    res.json(result);
  } catch (err) {
    res.status(502).json({ error: err instanceof Error ? err.message : 'Jago sync failed' });
  }
});
