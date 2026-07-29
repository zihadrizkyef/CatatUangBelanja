import cors from 'cors';
import express from 'express';

import { requireAuth } from './middleware/auth';
import { authRouter } from './routes/auth';
import { healthRouter } from './routes/health';
import { meRouter } from './routes/me';
import { syncRouter } from './routes/sync';

export const app = express();

app.use(cors());
app.use(express.json());

app.use('/health', healthRouter);
app.use('/auth', authRouter);
app.use('/me', requireAuth, meRouter);
app.use('/sync', syncRouter);

app.use((_req, res) => {
  res.status(404).json({ error: 'Not found' });
});
