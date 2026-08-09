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

// Runs the first sync immediately. No wallet to pick anymore — Bank Jago
// sync auto-creates and manages its own wallet per Kantong (see
// lib/jagoSync.ts's resolveKantongWallet).
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

  await prisma.user.update({
    where: { id: userId },
    data: {
      jagoRefreshToken: encryptToken(tokens.refreshToken),
      jagoHistoryId: null, // reset cursor — this connect's first sync does a full search
      jagoConnectedAt: new Date(),
    },
  });

  const result = await syncJagoForUser(userId);
  res.json({ connected: true, imported: result.imported });
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
