// Bridges the lowercase enum names the Flutter app already uses locally
// (`WalletType.cash.name`, etc. — see lib/models/*.dart) with Prisma's
// PascalCase enum values, so the wire format needs no translation on the
// client side beyond what it already does for SQLite.
import type {
  AppLockType,
  BudgetPeriod,
  CategoryType,
  Frequency,
  IconType,
  SyncStatus,
  Theme,
  TransactionSource,
  TransactionType,
  WalletType,
} from '@prisma/client';

function buildMaps<T extends string>(pairs: [string, T][]): [Record<string, T>, Record<T, string>] {
  const toPrisma = Object.fromEntries(pairs) as Record<string, T>;
  const toWire = Object.fromEntries(pairs.map(([wire, prisma]) => [prisma, wire])) as Record<T, string>;
  return [toPrisma, toWire];
}

export const [walletTypeToPrisma, walletTypeToWire] = buildMaps<WalletType>([
  ['cash', 'Cash'],
  ['bank', 'Bank'],
  ['eWallet', 'EWallet'],
  ['savings', 'Savings'],
  ['other', 'Other'],
]);

export const [iconTypeToPrisma, iconTypeToWire] = buildMaps<IconType>([
  ['system', 'System'],
  ['emoji', 'Emoji'],
  ['photo', 'Photo'],
]);

export const [categoryTypeToPrisma, categoryTypeToWire] = buildMaps<CategoryType>([
  ['income', 'Income'],
  ['expense', 'Expense'],
]);

export const [transactionTypeToPrisma, transactionTypeToWire] = buildMaps<TransactionType>([
  ['income', 'Income'],
  ['expense', 'Expense'],
  ['transfer', 'Transfer'],
]);

export const [syncStatusToPrisma, syncStatusToWire] = buildMaps<SyncStatus>([
  ['synced', 'Synced'],
  ['pending', 'Pending'],
  ['failed', 'Failed'],
]);

export const [budgetPeriodToPrisma, budgetPeriodToWire] = buildMaps<BudgetPeriod>([
  ['monthly', 'Monthly'],
  ['weekly', 'Weekly'],
  ['event', 'Event'],
]);

export const [frequencyToPrisma, frequencyToWire] = buildMaps<Frequency>([
  ['daily', 'Daily'],
  ['weekly', 'Weekly'],
  ['monthly', 'Monthly'],
]);

export const [themeToPrisma, themeToWire] = buildMaps<Theme>([
  ['light', 'Light'],
  ['dark', 'Dark'],
  ['system', 'System'],
]);

export const [appLockTypeToPrisma, appLockTypeToWire] = buildMaps<AppLockType>([
  ['pin', 'PIN'],
  ['biometric', 'Biometric'],
  ['none', 'None'],
]);

// Pull-only (doc note on Transaction.source/externalId in schema.prisma) —
// the client never pushes these back, so only the wire-direction map is
// used, but toPrisma is kept for symmetry/tests.
export const [transactionSourceToPrisma, transactionSourceToWire] = buildMaps<TransactionSource>([
  ['manual', 'Manual'],
  ['emailSync', 'EmailSync'],
]);
