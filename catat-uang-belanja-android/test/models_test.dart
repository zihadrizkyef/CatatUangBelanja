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

  test('Budget round-trips through toMap/fromMap', () {
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
  });
}
