import { Router } from 'express';

import { prisma } from '../lib/prisma';

export const meRouter = Router();

// Lets the Flutter client confirm a stored session token is still valid on
// cold start, and re-fetch profile info (e.g. after the user's Google name
// or avatar changed) without a full re-login.
meRouter.get('/', async (req, res) => {
  const user = await prisma.user.findUnique({ where: { id: req.userId } });
  if (!user) {
    res.status(404).json({ error: 'User not found' });
    return;
  }
  res.json({ id: user.id, email: user.email, name: user.name, avatar_url: user.avatarUrl });
});
