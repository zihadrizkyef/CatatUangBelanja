import express from 'express';
import request from 'supertest';
import { describe, expect, it } from 'vitest';

import { signSessionToken } from '../lib/jwt';
import { requireAuth } from './auth';

function buildApp() {
  const app = express();
  app.get('/protected', requireAuth, (req, res) => {
    res.json({ userId: req.userId });
  });
  return app;
}

describe('requireAuth', () => {
  it('rejects a request with no Authorization header', async () => {
    const res = await request(buildApp()).get('/protected');
    expect(res.status).toBe(401);
  });

  it('rejects a malformed Authorization header', async () => {
    const res = await request(buildApp()).get('/protected').set('Authorization', 'Token abc');
    expect(res.status).toBe(401);
  });

  it('rejects an invalid bearer token', async () => {
    const res = await request(buildApp()).get('/protected').set('Authorization', 'Bearer garbage');
    expect(res.status).toBe(401);
  });

  it('accepts a valid bearer token and attaches userId', async () => {
    const token = signSessionToken('user-42');
    const res = await request(buildApp()).get('/protected').set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ userId: 'user-42' });
  });
});
