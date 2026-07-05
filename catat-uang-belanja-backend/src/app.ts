import cors from 'cors';
import express from 'express';

import { healthRouter } from './routes/health';

export const app = express();

app.use(cors());
app.use(express.json());

app.use('/health', healthRouter);

app.use((_req, res) => {
  res.status(404).json({ error: 'Not found' });
});
