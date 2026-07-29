import request from 'supertest';
import { beforeEach, describe, expect, it, vi } from 'vitest';

const { verifyIdTokenMock, userUpsertMock } = vi.hoisted(() => ({
  verifyIdTokenMock: vi.fn(),
  userUpsertMock: vi.fn(),
}));

vi.mock('google-auth-library', () => ({
  OAuth2Client: class {
    verifyIdToken = verifyIdTokenMock;
  },
}));

vi.mock('../lib/prisma', () => ({
  prisma: { user: { upsert: userUpsertMock } },
}));

// vi.mock calls above are hoisted above this import by Vitest's transform,
// so `app` (and everything it pulls in) sees the mocked modules.
import { app } from '../app';

describe('POST /auth/google', () => {
  beforeEach(() => {
    verifyIdTokenMock.mockReset();
    userUpsertMock.mockReset();
  });

  it('returns 400 when id_token is missing from the body', async () => {
    const res = await request(app).post('/auth/google').send({});
    expect(res.status).toBe(400);
  });

  it('returns 401 when the Google token fails verification', async () => {
    verifyIdTokenMock.mockRejectedValue(new Error('bad token'));
    const res = await request(app).post('/auth/google').send({ id_token: 'abc' });
    expect(res.status).toBe(401);
  });

  it('returns 401 when the verified payload is missing sub/email', async () => {
    verifyIdTokenMock.mockResolvedValue({ getPayload: () => ({}) });
    const res = await request(app).post('/auth/google').send({ id_token: 'abc' });
    expect(res.status).toBe(401);
  });

  it('issues a session token and upserts the user by googleId on success', async () => {
    verifyIdTokenMock.mockResolvedValue({
      getPayload: () => ({
        sub: 'google-1',
        email: 'bunda@example.com',
        name: 'Bunda Sari',
        picture: 'https://example.com/avatar.png',
      }),
    });
    userUpsertMock.mockResolvedValue({
      id: 'user-1',
      email: 'bunda@example.com',
      name: 'Bunda Sari',
      avatarUrl: 'https://example.com/avatar.png',
    });

    const res = await request(app).post('/auth/google').send({ id_token: 'abc' });

    expect(res.status).toBe(200);
    expect(typeof res.body.token).toBe('string');
    expect(res.body.user).toEqual({
      id: 'user-1',
      email: 'bunda@example.com',
      name: 'Bunda Sari',
      avatar_url: 'https://example.com/avatar.png',
    });
    expect(userUpsertMock).toHaveBeenCalledWith(expect.objectContaining({ where: { googleId: 'google-1' } }));
  });
});
