import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart' show ThemeMode;

import '../db/app_database.dart';
import '../models/budget.dart';
import '../models/budget_status.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';

/// Single app-wide state holder (provided via `provider` at the app root).
/// Holds in-memory lists loaded from SQLite on [load]; every mutation writes
/// to SQLite first, then updates the in-memory list and calls
/// [notifyListeners]. There is no other state layer — new features extend
/// this repository.
class FinanceRepository extends ChangeNotifier {
  FinanceRepository({AppDatabase? appDatabase}) : _appDatabase = appDatabase ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  List<Wallet> _wallets = [];
  List<Category> _categories = [];
  List<Transaction> _transactions = [];
  List<Budget> _budgets = [];

  /// Defaults to following the OS setting; [toggleDarkMode] pins it to an
  /// explicit light/dark choice, mirroring the mockup's own
  /// override-vs-system-preference behavior.
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  void toggleDarkMode() {
    final isCurrentlyDark = _themeMode == ThemeMode.dark ||
        (_themeMode == ThemeMode.system &&
            PlatformDispatcher.instance.platformBrightness == Brightness.dark);
    _themeMode = isCurrentlyDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  List<Wallet> get wallets => List.unmodifiable(_wallets);
  List<Category> get categories => List.unmodifiable(_categories);
  List<Budget> get budgets => List.unmodifiable(_budgets);

  /// Active (non-deleted) transactions. Soft-deleted rows stay in
  /// [_transactions] for sync safety (doc 4.1/4.10) but are hidden here.
  List<Transaction> get transactions =>
      List.unmodifiable(_transactions.where((t) => !t.isDeleted));

  Future<void> load() async {
    final db = await _appDatabase.database;

    final walletRows = await db.query('wallets');
    final categoryRows = await db.query('categories');
    final transactionRows = await db.query('transactions');
    final budgetRows = await db.query('budgets');

    _wallets = walletRows.map(Wallet.fromMap).toList();
    _categories = categoryRows.map(Category.fromMap).toList();
    _transactions = transactionRows.map(Transaction.fromMap).toList();
    _budgets = budgetRows.map(Budget.fromMap).toList();

    notifyListeners();
  }

  Future<void> addWallet(Wallet wallet) async {
    final db = await _appDatabase.database;
    await db.insert('wallets', wallet.toMap());
    _wallets = [..._wallets, wallet];
    notifyListeners();
  }

  Future<void> updateWallet(Wallet wallet) async {
    final db = await _appDatabase.database;
    await db.update('wallets', wallet.toMap(), where: 'id = ?', whereArgs: [wallet.id]);
    _wallets = [for (final w in _wallets) if (w.id == wallet.id) wallet else w];
    notifyListeners();
  }

  Future<void> addCategory(Category category) async {
    final db = await _appDatabase.database;
    await db.insert('categories', category.toMap());
    _categories = [..._categories, category];
    notifyListeners();
  }

  Future<void> addTransaction(Transaction transaction) async {
    final db = await _appDatabase.database;
    await db.insert('transactions', transaction.toMap());
    _transactions = [..._transactions, transaction];
    notifyListeners();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final db = await _appDatabase.database;
    final updated = transaction.copyWith(updatedAt: DateTime.now());
    await db.update('transactions', updated.toMap(), where: 'id = ?', whereArgs: [updated.id]);
    _transactions = [for (final t in _transactions) if (t.id == updated.id) updated else t];
    notifyListeners();
  }

  /// Soft delete (doc 4.1): marks the row deleted instead of removing it, so
  /// it stays safe for the future sync feature. [transactions] filters these
  /// out; the raw list above still contains them.
  Future<void> deleteTransaction(String transactionId) async {
    final existing = _transactions.firstWhere((t) => t.id == transactionId);
    final deleted = existing.copyWith(isDeleted: true, updatedAt: DateTime.now());

    final db = await _appDatabase.database;
    await db.update('transactions', deleted.toMap(), where: 'id = ?', whereArgs: [transactionId]);
    _transactions = [for (final t in _transactions) if (t.id == transactionId) deleted else t];
    notifyListeners();
  }

  Future<void> setBudget(Budget budget) async {
    final db = await _appDatabase.database;
    final exists = _budgets.any((b) => b.id == budget.id);

    if (exists) {
      await db.update('budgets', budget.toMap(), where: 'id = ?', whereArgs: [budget.id]);
      _budgets = [for (final b in _budgets) if (b.id == budget.id) budget else b];
    } else {
      await db.insert('budgets', budget.toMap());
      _budgets = [..._budgets, budget];
    }
    notifyListeners();
  }

  /// Budgets don't need [deleteTransaction]'s soft-delete (no sync/history
  /// requirement on them), so this is a straightforward hard delete.
  Future<void> deleteBudget(String budgetId) async {
    final db = await _appDatabase.database;
    await db.delete('budgets', where: 'id = ?', whereArgs: [budgetId]);
    _budgets = _budgets.where((b) => b.id != budgetId).toList();
    notifyListeners();
  }

  /// Wallet balance, derived on the fly from active transactions (doc 4.2) —
  /// never stored. Transfers apply to both the source and target wallet.
  int balanceOf(String walletId) {
    var balance = 0;
    for (final t in transactions) {
      switch (t.type) {
        case TransactionType.income:
          if (t.walletId == walletId) balance += t.amount;
        case TransactionType.expense:
          if (t.walletId == walletId) balance -= t.amount;
        case TransactionType.transfer:
          if (t.walletId == walletId) balance -= t.amount;
          if (t.targetWalletId == walletId) balance += t.amount;
      }
    }
    return balance;
  }

  int get totalBalance => _wallets.fold(0, (sum, w) => sum + balanceOf(w.id));

  /// Amount spent against [categoryId] in the current calendar month,
  /// computed on demand (doc 4.4) rather than tracked as a running total.
  int budgetUsageThisMonth(String categoryId) {
    final now = DateTime.now();
    var used = 0;
    for (final t in transactions) {
      if (t.type == TransactionType.expense &&
          t.categoryId == categoryId &&
          t.dateTime.year == now.year &&
          t.dateTime.month == now.month) {
        used += t.amount;
      }
    }
    return used;
  }

  /// Every [Budget] paired with its category and this month's usage,
  /// sorted by usage percentage descending — shared by any screen that
  /// ranks/displays budget progress (Beranda, Rangkuman, Anggaran).
  List<BudgetStatus> get budgetStatuses {
    final statuses = <BudgetStatus>[];
    for (final budget in _budgets) {
      final category = _categories.where((c) => c.id == budget.categoryId).firstOrNull;
      if (category == null) continue;
      final used = budgetUsageThisMonth(budget.categoryId);
      final pct = budget.limitAmount == 0 ? 0 : (used * 100 / budget.limitAmount).round();
      statuses.add(BudgetStatus(category: category, budget: budget, used: used, pct: pct));
    }
    statuses.sort((a, b) => b.pct.compareTo(a.pct));
    return List.unmodifiable(statuses);
  }
}
