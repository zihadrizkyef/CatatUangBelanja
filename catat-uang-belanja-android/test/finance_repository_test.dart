import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;

import 'package:catat_uang_belanja/db/app_database.dart';
import 'package:catat_uang_belanja/models/budget.dart';
import 'package:catat_uang_belanja/models/icon_type.dart';
import 'package:catat_uang_belanja/models/transaction.dart';
import 'package:catat_uang_belanja/models/wallet.dart';
import 'package:catat_uang_belanja/repositories/finance_repository.dart';

void main() {
  late FinanceRepository repository;
  late String cashWalletId;
  late String secondWalletId;
  late String kitchenCategoryId;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final dbPath = join(await databaseFactory.getDatabasesPath(), 'catat_uang_belanja.db');
    final file = File(dbPath);
    if (await file.exists()) {
      await file.delete();
    }
  });

  setUp(() async {
    // Isolate each test: wipe transactions/budgets so balances computed in
    // one test don't leak into the next (wallets/categories stay seeded).
    final db = await AppDatabase.instance.database;
    await db.delete('transactions');
    await db.delete('budgets');

    repository = FinanceRepository();
    await repository.load();

    cashWalletId = repository.wallets.first.id;
    kitchenCategoryId = repository.categories.firstWhere((c) => c.name == 'Belanja Dapur').id;

    final bankWallet = Wallet(
      id: 'wallet-${DateTime.now().microsecondsSinceEpoch}',
      name: 'Rekening Bank',
      type: WalletType.bank,
      color: '#DCD3F0',
      iconType: IconType.system,
      iconValue: 'wallet_bank',
      createdAt: DateTime.now(),
    );
    await repository.addWallet(bankWallet);
    secondWalletId = bankWallet.id;
  });

  test('load() populates the seeded wallet and household categories', () {
    expect(repository.wallets.length, 2);
    expect(repository.categories.length, 13);
  });

  test('balanceOf sums income/expense and totalBalance sums all wallets', () async {
    final now = DateTime.now();
    await repository.addTransaction(Transaction(
      id: 'tx-income',
      type: TransactionType.income,
      amount: 500000,
      walletId: cashWalletId,
      categoryId: kitchenCategoryId,
      dateTime: now,
      createdAt: now,
      updatedAt: now,
    ));
    await repository.addTransaction(Transaction(
      id: 'tx-expense',
      type: TransactionType.expense,
      amount: 150000,
      walletId: cashWalletId,
      categoryId: kitchenCategoryId,
      dateTime: now,
      createdAt: now,
      updatedAt: now,
    ));

    expect(repository.balanceOf(cashWalletId), 350000);
    expect(repository.totalBalance, 350000);
  });

  test('transfer moves balance from source wallet to target wallet without affecting totalBalance', () async {
    final now = DateTime.now();
    await repository.addTransaction(Transaction(
      id: 'tx-seed-income',
      type: TransactionType.income,
      amount: 1000000,
      walletId: cashWalletId,
      dateTime: now,
      createdAt: now,
      updatedAt: now,
    ));
    final totalBefore = repository.totalBalance;

    await repository.addTransaction(Transaction(
      id: 'tx-transfer',
      type: TransactionType.transfer,
      amount: 200000,
      walletId: cashWalletId,
      targetWalletId: secondWalletId,
      dateTime: now,
      createdAt: now,
      updatedAt: now,
    ));

    expect(repository.balanceOf(cashWalletId), 800000);
    expect(repository.balanceOf(secondWalletId), 200000);
    expect(repository.totalBalance, totalBefore);
  });

  test('deleteTransaction soft-deletes: hidden from transactions, still counted as deleted', () async {
    final now = DateTime.now();
    await repository.addTransaction(Transaction(
      id: 'tx-to-delete',
      type: TransactionType.expense,
      amount: 75000,
      walletId: cashWalletId,
      categoryId: kitchenCategoryId,
      dateTime: now,
      createdAt: now,
      updatedAt: now,
    ));
    expect(repository.balanceOf(cashWalletId), -75000);

    await repository.deleteTransaction('tx-to-delete');

    expect(repository.transactions.where((t) => t.id == 'tx-to-delete'), isEmpty);
    expect(repository.balanceOf(cashWalletId), 0);
  });

  test('budgetUsageThisMonth sums only this month\'s expense transactions for the category', () async {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 15);

    await repository.addTransaction(Transaction(
      id: 'tx-this-month',
      type: TransactionType.expense,
      amount: 300000,
      walletId: cashWalletId,
      categoryId: kitchenCategoryId,
      dateTime: now,
      createdAt: now,
      updatedAt: now,
    ));
    await repository.addTransaction(Transaction(
      id: 'tx-last-month',
      type: TransactionType.expense,
      amount: 999999,
      walletId: cashWalletId,
      categoryId: kitchenCategoryId,
      dateTime: lastMonth,
      createdAt: lastMonth,
      updatedAt: lastMonth,
    ));

    expect(repository.budgetUsageThisMonth(kitchenCategoryId), 300000);

    await repository.setBudget(Budget(
      id: 'budget-kitchen',
      categoryId: kitchenCategoryId,
      limitAmount: 1000000,
      createdAt: now,
      updatedAt: now,
    ));
    expect(repository.budgets.length, 1);
  });
}
