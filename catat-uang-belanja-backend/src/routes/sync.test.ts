import request from 'supertest';
import { beforeEach, describe, expect, it, vi } from 'vitest';

import { signSessionToken } from '../lib/jwt';

const prismaMock = vi.hoisted(() => ({
  $transaction: vi.fn(async (cb: (tx: unknown) => Promise<void>) => cb(prismaMock)),
  wallet: { upsert: vi.fn(), findMany: vi.fn().mockResolvedValue([]) },
  category: { upsert: vi.fn(), findMany: vi.fn().mockResolvedValue([]) },
  recurringTransaction: { upsert: vi.fn(), findMany: vi.fn().mockResolvedValue([]) },
  budget: { upsert: vi.fn(), findUnique: vi.fn().mockResolvedValue(null), findMany: vi.fn().mockResolvedValue([]) },
  transaction: {
    upsert: vi.fn(),
    findUnique: vi.fn().mockResolvedValue(null),
    findMany: vi.fn().mockResolvedValue([]),
  },
  settings: { upsert: vi.fn(), updateMany: vi.fn(), findFirst: vi.fn().mockResolvedValue(null) },
}));

vi.mock('../lib/prisma', () => ({ prisma: prismaMock }));

// vi.mock calls above are hoisted above this import by Vitest's transform,
// so `app` (and everything it pulls in) sees the mocked modules.
import { app } from '../app';

const token = signSessionToken('user-1');
const authHeader = `Bearer ${token}`;

describe('sync routes', () => {
  beforeEach(() => {
    vi.clearAllMocks();
    prismaMock.wallet.findMany.mockResolvedValue([]);
    prismaMock.category.findMany.mockResolvedValue([]);
    prismaMock.recurringTransaction.findMany.mockResolvedValue([]);
    prismaMock.budget.findMany.mockResolvedValue([]);
    prismaMock.budget.findUnique.mockResolvedValue(null);
    prismaMock.transaction.findMany.mockResolvedValue([]);
    prismaMock.transaction.findUnique.mockResolvedValue(null);
    prismaMock.settings.findFirst.mockResolvedValue(null);
  });

  it('rejects push without a session token', async () => {
    const res = await request(app).post('/sync/push').send({ wallets: [] });
    expect(res.status).toBe(401);
  });

  it('rejects pull without a session token', async () => {
    const res = await request(app).get('/sync/pull');
    expect(res.status).toBe(401);
  });

  it('rejects a push body with a malformed wallet', async () => {
    const res = await request(app)
      .post('/sync/push')
      .set('Authorization', authHeader)
      .send({ wallets: [{ id: 'not-a-uuid', name: 'Dompet Tunai' }] });
    expect(res.status).toBe(400);
  });

  it('upserts an empty push and returns a server_time cursor', async () => {
    const res = await request(app).post('/sync/push').set('Authorization', authHeader).send({});
    expect(res.status).toBe(200);
    expect(typeof res.body.server_time).toBe('string');
    expect(prismaMock.$transaction).toHaveBeenCalledOnce();
  });

  it('pushes a wallet, mapping wire enum values to Prisma enum values', async () => {
    const wallet = {
      id: 'a02749d7-39b8-4e46-a31b-ea7858503a44',
      name: 'Dompet Tunai',
      type: 'cash',
      color: '#FCE0E1',
      icon_type: 'system',
      icon_value: 'wallet_cash',
      is_archived: false,
      created_at: new Date().toISOString(),
    };
    const res = await request(app).post('/sync/push').set('Authorization', authHeader).send({ wallets: [wallet] });
    expect(res.status).toBe(200);
    expect(prismaMock.wallet.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: wallet.id },
        create: expect.objectContaining({ type: 'Cash', iconType: 'System', userId: 'user-1' }),
      }),
    );
  });

  it('drops a stale transaction push when the server copy is newer (last-write-wins)', async () => {
    const id = 'c401d7f6-631b-444d-9646-f4382c920b8e';
    prismaMock.transaction.findUnique.mockResolvedValue({ updatedAt: new Date('2026-01-02T00:00:00Z') });
    const staleTxn = {
      id,
      type: 'expense',
      amount: 10000,
      wallet_id: 'c491f891-14fa-4dc8-9ec0-a82892e9ac09',
      date_time: new Date('2026-01-01T00:00:00Z').toISOString(),
      is_deleted: false,
      created_at: new Date('2026-01-01T00:00:00Z').toISOString(),
      updated_at: new Date('2026-01-01T00:00:00Z').toISOString(), // older than server's
    };
    const res = await request(app)
      .post('/sync/push')
      .set('Authorization', authHeader)
      .send({ transactions: [staleTxn] });
    expect(res.status).toBe(200);
    expect(prismaMock.transaction.upsert).not.toHaveBeenCalled();
  });

  it('pulls entities and maps Prisma enum values back to wire (lowercase) values', async () => {
    prismaMock.wallet.findMany.mockResolvedValue([
      {
        id: 'w1',
        name: 'Dompet Tunai',
        type: 'Cash',
        color: '#FCE0E1',
        iconType: 'System',
        iconValue: 'wallet_cash',
        isArchived: false,
        createdAt: new Date('2026-01-01T00:00:00Z'),
      },
    ]);

    const res = await request(app).get('/sync/pull').set('Authorization', authHeader);
    expect(res.status).toBe(200);
    expect(res.body.wallets).toEqual([
      {
        id: 'w1',
        name: 'Dompet Tunai',
        type: 'cash',
        color: '#FCE0E1',
        icon_type: 'system',
        icon_value: 'wallet_cash',
        is_archived: false,
        created_at: '2026-01-01T00:00:00.000Z',
      },
    ]);
  });
});
