import type { NextFunction, Request, Response } from 'express';

import { verifySessionToken } from '../lib/jwt';

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      userId: string;
    }
  }
}

export function requireAuth(req: Request, res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Missing bearer token' });
    return;
  }

  try {
    req.userId = verifySessionToken(header.slice('Bearer '.length));
    next();
  } catch {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
}
