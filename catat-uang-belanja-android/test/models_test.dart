import 'package:flutter_test/flutter_test.dart';

import 'package:catat_uang_belanja/models/budget.dart';
import 'package:catat_uang_belanja/models/category.dart';
import 'package:catat_uang_belanja/models/icon_type.dart';
import 'package:catat_uang_belanja/models/transaction.dart';
import 'package:catat_uang_belanja/models/wallet.dart';

void main() {
  test('Wallet round-trips through toMap/fromMap', () {
    final wallet = Wallet(
      id: 'w1',
      name: 'Dompet Tunai',
      type: WalletType.cash,
      color: '#F7C6D9',
      iconType: IconType.system,
      iconValue: 'wallet_cash',
      createdAt: DateTime.utc(2026, 1, 1),
    );

    final restored = Wallet.fromMap(wallet.toMap());

    expect(restored.id, wallet.id);
    expect(restored.name, wallet.name);
    expect(restored.type, wallet.type);
    expect(restored.iconType, wallet.iconType);
    expect(restored.isArchived, false);
    expect(restored.createdAt, wallet.createdAt);
  });

  test('Category round-trips through toMap/fromMap', () {
    final category = Category(
      id: 'c1',
      name: 'Belanja Dapur',
      type: CategoryType.expense,
      color: '#FBD8B5',
      iconType: IconType.emoji,
      iconValue: '🧺',
      isSystem: true,
    );

    final restored = Category.fromMap(category.toMap());

    expect(restored.name, 'Belanja Dapur');
    expect(restored.type, CategoryType.expense);
    expect(restored.isSystem, true);
  });

  test('Transaction round-trips and preserves nullable transfer fields', () {
    final now = DateTime.utc(2026, 7, 5, 10, 30);
    final transaction = Transaction(
      id: 't1',
      type: TransactionType.transfer,
      amount: 50000,
      walletId: 'w1',
      targetWalletId: 'w2',
      dateTime: now,
      createdAt: now,
      updatedAt: now,
    );

    final restored = Transaction.fromMap(transaction.toMap());

    expect(restored.type, TransactionType.transfer);
    expect(restored.targetWalletId, 'w2');
    expect(restored.categoryId, isNull);
    expect(restored.isDeleted, false);
    expect(restored.syncStatus, SyncStatus.synced);
  });

  test('Budget round-trips through toMap/fromMap, defaulting to monthly/day-1', () {
    final now = DateTime.utc(2026, 7, 1);
    final budget = Budget(
      id: 'b1',
      categoryId: 'c1',
      limitAmount: 1000000,
      createdAt: now,
      updatedAt: now,
    );

    final restored = Budget.fromMap(budget.toMap());

    expect(restored.period, BudgetPeriod.monthly);
    expect(restored.limitAmount, 1000000);
    expect(restored.resetAnchor, isNull);
    expect(restored.triggerCategoryId, isNull);
    expect(restored.currentPeriodStartedAt, now);
  });

  test('Budget round-trips a weekly period with its reset-day anchor', () {
    final now = DateTime.utc(2026, 7, 1);
    final periodStart = DateTime.utc(2026, 6, 29);
    final budget = Budget(
      id: 'b2',
      categoryId: 'c1',
      period: BudgetPeriod.weekly,
      resetAnchor: DateTime.monday,
      limitAmount: 300000,
      currentPeriodStartedAt: periodStart,
      createdAt: now,
      updatedAt: now,
    );

    final restored = Budget.fromMap(budget.toMap());

    expect(restored.period, BudgetPeriod.weekly);
    expect(restored.resetAnchor, DateTime.monday);
    expect(restored.currentPeriodStartedAt, periodStart);
  });

  test('Budget round-trips an event period with its trigger category', () {
    final now = DateTime.utc(2026, 7, 1);
    final budget = Budget(
      id: 'b3',
      categoryId: 'c1',
      period: BudgetPeriod.event,
      triggerCategoryId: 'income-salary',
      limitAmount: 500000,
      createdAt: now,
      updatedAt: now,
    );

    final restored = Budget.fromMap(budget.toMap());

    expect(restored.period, BudgetPeriod.event);
    expect(restored.triggerCategoryId, 'income-salary');
    expect(restored.resetAnchor, isNull);
  });
}
