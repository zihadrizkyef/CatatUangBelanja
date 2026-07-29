import { Router } from 'express';
import { z } from 'zod';

import {
  appLockTypeToPrisma,
  appLockTypeToWire,
  budgetPeriodToPrisma,
  budgetPeriodToWire,
  categoryTypeToPrisma,
  categoryTypeToWire,
  frequencyToPrisma,
  frequencyToWire,
  iconTypeToPrisma,
  iconTypeToWire,
  syncStatusToWire,
  themeToPrisma,
  themeToWire,
  transactionTypeToPrisma,
  transactionTypeToWire,
  walletTypeToPrisma,
  walletTypeToWire,
} from '../lib/enum-maps';
import { prisma } from '../lib/prisma';
import { requireAuth } from '../middleware/auth';

export const syncRouter = Router();
syncRouter.use(requireAuth);

// --- Push: doc 4.10 — pending local changes are upserted, last-write-wins
// on `updated_at` for entities that carry one client-side (Transaction,
// Budget). Wallet/Category/RecurringTransaction/Settings have no
// client-tracked `updated_at` (see doc 5.1/5.3/5.5/5.6), so the last push
// simply wins for those — acceptable since they change far less often than
// transactions and aren't described in the spec as needing conflict
// resolution.

const walletInput = z.object({
  id: z.string().uuid(),
  name: z.string().min(1),
  type: z.enum(['cash', 'bank', 'eWallet', 'savings', 'other']),
  color: z.string().min(1),
  icon_type: z.enum(['system', 'emoji', 'photo']),
  icon_value: z.string().min(1),
  is_archived: z.boolean(),
  created_at: z.string().datetime(),
});

const categoryInput = z.object({
  id: z.string().uuid(),
  name: z.string().min(1),
  type: z.enum(['income', 'expense']),
  color: z.string().min(1),
  icon_type: z.enum(['system', 'emoji', 'photo']),
  icon_value: z.string().min(1),
  is_system: z.boolean(),
});

const transactionInput = z.object({
  id: z.string().uuid(),
  type: z.enum(['income', 'expense', 'transfer']),
  amount: z.number().int(),
  wallet_id: z.string().uuid(),
  target_wallet_id: z.string().uuid().nullable().optional(),
  category_id: z.string().uuid().nullable().optional(),
  date_time: z.string().datetime(),
  note: z.string().nullable().optional(),
  attachment_url: z.string().nullable().optional(),
  recurring_id: z.string().uuid().nullable().optional(),
  is_deleted: z.boolean(),
  created_at: z.string().datetime(),
  updated_at: z.string().datetime(),
});

const budgetInput = z.object({
  id: z.string().uuid(),
  category_id: z.string().uuid(),
  period: z.enum(['monthly', 'weekly', 'event']),
  reset_anchor: z.number().int().nullable().optional(),
  trigger_category_id: z.string().uuid().nullable().optional(),
  limit_amount: z.number().int(),
  current_period_started_at: z.string().datetime(),
  created_at: z.string().datetime(),
  updated_at: z.string().datetime(),
});

const recurringInput = z.object({
  id: z.string().uuid(),
  type: z.enum(['income', 'expense']),
  amount: z.number().int(),
  wallet_id: z.string().uuid(),
  category_id: z.string().uuid(),
  frequency: z.enum(['daily', 'weekly', 'monthly']),
  start_date: z.string().datetime(),
  next_run_at: z.string().datetime(),
  is_active: z.boolean(),
  note: z.string().nullable().optional(),
});

const settingsInput = z.object({
  theme: z.enum(['light', 'dark', 'system']),
  background_theme: z.string().nullable().optional(),
  app_lock_enabled: z.boolean(),
  app_lock_type: z.enum(['none', 'pin', 'biometric']),
});

const pushSchema = z.object({
  wallets: z.array(walletInput).default([]),
  categories: z.array(categoryInput).default([]),
  transactions: z.array(transactionInput).default([]),
  budgets: z.array(budgetInput).default([]),
  recurring_transactions: z.array(recurringInput).default([]),
  settings: settingsInput.nullable().optional(),
});

syncRouter.post('/push', async (req, res) => {
  const parsed = pushSchema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid request body', details: parsed.error.flatten() });
    return;
  }
  const userId = req.userId;
  const body = parsed.data;

  await prisma.$transaction(async (tx) => {
    for (const w of body.wallets) {
      await tx.wallet.upsert({
        where: { id: w.id },
        update: {
          name: w.name,
          type: walletTypeToPrisma[w.type],
          color: w.color,
          iconType: iconTypeToPrisma[w.icon_type],
          iconValue: w.icon_value,
          isArchived: w.is_archived,
        },
        create: {
          id: w.id,
          userId,
          name: w.name,
          type: walletTypeToPrisma[w.type],
          color: w.color,
          iconType: iconTypeToPrisma[w.icon_type],
          iconValue: w.icon_value,
          isArchived: w.is_archived,
          createdAt: new Date(w.created_at),
        },
      });
    }

    for (const c of body.categories) {
      await tx.category.upsert({
        where: { id: c.id },
        update: {
          name: c.name,
          type: categoryTypeToPrisma[c.type],
          color: c.color,
          iconType: iconTypeToPrisma[c.icon_type],
          iconValue: c.icon_value,
          isSystem: c.is_system,
        },
        create: {
          id: c.id,
          userId,
          name: c.name,
          type: categoryTypeToPrisma[c.type],
          color: c.color,
          iconType: iconTypeToPrisma[c.icon_type],
          iconValue: c.icon_value,
          isSystem: c.is_system,
        },
      });
    }

    // Budget/RecurringTransaction/Transaction reference wallets/categories —
    // pushed after those, and in dependency order among themselves
    // (RecurringTransaction before Transaction, since Transaction.recurringId
    // may reference one from the same batch).
    for (const r of body.recurring_transactions) {
      await tx.recurringTransaction.upsert({
        where: { id: r.id },
        update: {
          type: transactionTypeToPrisma[r.type],
          amount: r.amount,
          walletId: r.wallet_id,
          categoryId: r.category_id,
          frequency: frequencyToPrisma[r.frequency],
          startDate: new Date(r.start_date),
          nextRunAt: new Date(r.next_run_at),
          isActive: r.is_active,
          note: r.note ?? null,
        },
        create: {
          id: r.id,
          userId,
          type: transactionTypeToPrisma[r.type],
          amount: r.amount,
          walletId: r.wallet_id,
          categoryId: r.category_id,
          frequency: frequencyToPrisma[r.frequency],
          startDate: new Date(r.start_date),
          nextRunAt: new Date(r.next_run_at),
          isActive: r.is_active,
          note: r.note ?? null,
        },
      });
    }

    for (const b of body.budgets) {
      const existing = await tx.budget.findUnique({ where: { id: b.id }, select: { updatedAt: true } });
      if (existing && existing.updatedAt.getTime() > new Date(b.updated_at).getTime()) {
        continue; // server has a newer edit — last-write-wins, client's stale write is dropped
      }
      await tx.budget.upsert({
        where: { id: b.id },
        update: {
          categoryId: b.category_id,
          period: budgetPeriodToPrisma[b.period],
          resetAnchor: b.reset_anchor ?? null,
          triggerCategoryId: b.trigger_category_id ?? null,
          limitAmount: b.limit_amount,
          currentPeriodStartedAt: new Date(b.current_period_started_at),
        },
        create: {
          id: b.id,
          userId,
          categoryId: b.category_id,
          period: budgetPeriodToPrisma[b.period],
          resetAnchor: b.reset_anchor ?? null,
          triggerCategoryId: b.trigger_category_id ?? null,
          limitAmount: b.limit_amount,
          currentPeriodStartedAt: new Date(b.current_period_started_at),
          createdAt: new Date(b.created_at),
        },
      });
    }

    for (const t of body.transactions) {
      const existing = await tx.transaction.findUnique({ where: { id: t.id }, select: { updatedAt: true } });
      if (existing && existing.updatedAt.getTime() > new Date(t.updated_at).getTime()) {
        continue;
      }
      await tx.transaction.upsert({
        where: { id: t.id },
        update: {
          type: transactionTypeToPrisma[t.type],
          amount: t.amount,
          walletId: t.wallet_id,
          targetWalletId: t.target_wallet_id ?? null,
          categoryId: t.category_id ?? null,
          dateTime: new Date(t.date_time),
          note: t.note ?? null,
          attachmentUrl: t.attachment_url ?? null,
          recurringId: t.recurring_id ?? null,
          isDeleted: t.is_deleted,
          syncStatus: 'Synced',
        },
        create: {
          id: t.id,
          userId,
          type: transactionTypeToPrisma[t.type],
          amount: t.amount,
          walletId: t.wallet_id,
          targetWalletId: t.target_wallet_id ?? null,
          categoryId: t.category_id ?? null,
          dateTime: new Date(t.date_time),
          note: t.note ?? null,
          attachmentUrl: t.attachment_url ?? null,
          recurringId: t.recurring_id ?? null,
          isDeleted: t.is_deleted,
          syncStatus: 'Synced',
          createdAt: new Date(t.created_at),
        },
      });
    }

    if (body.settings) {
      const s = body.settings;
      await tx.settings.upsert({
        where: { userId },
        update: {
          theme: themeToPrisma[s.theme],
          backgroundTheme: s.background_theme ?? null,
          appLockEnabled: s.app_lock_enabled,
          appLockType: appLockTypeToPrisma[s.app_lock_type],
          lastSyncedAt: new Date(),
        },
        create: {
          userId,
          theme: themeToPrisma[s.theme],
          backgroundTheme: s.background_theme ?? null,
          appLockEnabled: s.app_lock_enabled,
          appLockType: appLockTypeToPrisma[s.app_lock_type],
          lastSyncedAt: new Date(),
        },
      });
    } else {
      await tx.settings.updateMany({ where: { userId }, data: { lastSyncedAt: new Date() } });
    }
  });

  res.json({ server_time: new Date().toISOString() });
});

// --- Pull: everything touched (created or updated) since `since`, per
// entity's `updatedAt` (server-managed for Wallet/Category/RecurringTransaction
// even though the client doesn't track it locally — see schema.prisma notes).

const pullQuerySchema = z.object({ since: z.string().datetime().optional() });

syncRouter.get('/pull', async (req, res) => {
  const parsed = pullQuerySchema.safeParse(req.query);
  if (!parsed.success) {
    res.status(400).json({ error: 'Invalid query', details: parsed.error.flatten() });
    return;
  }
  const userId = req.userId;
  const since = parsed.data.since ? new Date(parsed.data.since) : new Date(0);
  const serverTime = new Date();

  const [wallets, categories, transactions, budgets, recurring, settings] = await Promise.all([
    prisma.wallet.findMany({ where: { userId, updatedAt: { gt: since } } }),
    prisma.category.findMany({ where: { userId, updatedAt: { gt: since } } }),
    prisma.transaction.findMany({ where: { userId, updatedAt: { gt: since } } }),
    prisma.budget.findMany({ where: { userId, updatedAt: { gt: since } } }),
    prisma.recurringTransaction.findMany({ where: { userId, updatedAt: { gt: since } } }),
    prisma.settings.findFirst({ where: { userId, updatedAt: { gt: since } } }),
  ]);

  res.json({
    server_time: serverTime.toISOString(),
    wallets: wallets.map((w) => ({
      id: w.id,
      name: w.name,
      type: walletTypeToWire[w.type],
      color: w.color,
      icon_type: iconTypeToWire[w.iconType],
      icon_value: w.iconValue,
      is_archived: w.isArchived,
      created_at: w.createdAt.toISOString(),
    })),
    categories: categories.map((c) => ({
      id: c.id,
      name: c.name,
      type: categoryTypeToWire[c.type],
      color: c.color,
      icon_type: iconTypeToWire[c.iconType],
      icon_value: c.iconValue,
      is_system: c.isSystem,
    })),
    transactions: transactions.map((t) => ({
      id: t.id,
      type: transactionTypeToWire[t.type],
      amount: t.amount,
      wallet_id: t.walletId,
      target_wallet_id: t.targetWalletId,
      category_id: t.categoryId,
      date_time: t.dateTime.toISOString(),
      note: t.note,
      attachment_url: t.attachmentUrl,
      recurring_id: t.recurringId,
      is_deleted: t.isDeleted,
      sync_status: syncStatusToWire[t.syncStatus],
      created_at: t.createdAt.toISOString(),
      updated_at: t.updatedAt.toISOString(),
    })),
    budgets: budgets.map((b) => ({
      id: b.id,
      category_id: b.categoryId,
      period: budgetPeriodToWire[b.period],
      reset_anchor: b.resetAnchor,
      trigger_category_id: b.triggerCategoryId,
      limit_amount: b.limitAmount,
      current_period_started_at: b.currentPeriodStartedAt.toISOString(),
      created_at: b.createdAt.toISOString(),
      updated_at: b.updatedAt.toISOString(),
    })),
    recurring_transactions: recurring.map((r) => ({
      id: r.id,
      type: transactionTypeToWire[r.type],
      amount: r.amount,
      wallet_id: r.walletId,
      category_id: r.categoryId,
      frequency: frequencyToWire[r.frequency],
      start_date: r.startDate.toISOString(),
      next_run_at: r.nextRunAt.toISOString(),
      is_active: r.isActive,
      note: r.note,
    })),
    settings: settings
      ? {
          theme: themeToWire[settings.theme],
          background_theme: settings.backgroundTheme,
          app_lock_enabled: settings.appLockEnabled,
          app_lock_type: appLockTypeToWire[settings.appLockType],
          last_synced_at: settings.lastSyncedAt?.toISOString() ?? null,
        }
      : null,
  });
});
