import { OAuth2Client } from 'google-auth-library';
import { Router } from 'express';
import { z } from 'zod';

import { signSessionToken } from '../lib/jwt';
import { prisma } from '../lib/prisma';

// Web OAuth Client ID also used as the Android app's `serverClientId` —
// Google requires a web client for backend-side ID token verification even
// when the token was minted by a mobile client (see README setup notes).
const googleClientId = process.env.GOOGLE_CLIENT_ID;
const client = new OAuth2Client(googleClientId);

export const authRouter = Router();

const googleAuthSchema = z.object({ id_token: z.string().min(1) });

// Login is Google Sign-In only (doc 4.10/6.1) — the Flutter app obtains a
// Google ID token via `google_sign_in`, and this endpoint exchanges it for
// our own session token after verifying it really came from Google.
authRouter.post('/google', async (req, res) => {
  if (!googleClientId) {
    res.status(500).json({ error: 'Server not configured for Google Sign-In (GOOGLE_CLIENT_ID missing)' });
    return;
  }

  const parsed = googleAuthSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid request body', details: parsed.error.flatten() });
    return;
  }

  let payload;
  try {
    const ticket = await client.verifyIdToken({ idToken: parsed.data.id_token, audience: googleClientId });
    payload = ticket.getPayload();
  } catch {
    res.status(401).json({ error: 'Invalid Google ID token' });
    return;
  }

  if (!payload?.sub || !payload.email) {
    res.status(401).json({ error: 'Google token missing required claims' });
    return;
  }

  const user = await prisma.user.upsert({
    where: { googleId: payload.sub },
    update: { email: payload.email, name: payload.name ?? payload.email, avatarUrl: payload.picture },
    create: {
      googleId: payload.sub,
      email: payload.email,
      name: payload.name ?? payload.email,
      avatarUrl: payload.picture,
      settings: { create: {} },
    },
  });

  res.json({
    token: signSessionToken(user.id),
    user: { id: user.id, email: user.email, name: user.name, avatar_url: user.avatarUrl },
  });
});
