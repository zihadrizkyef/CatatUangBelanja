import 'dart:math';

import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart' show ThemeMode;
import 'package:sqflite/sqflite.dart' show ConflictAlgorithm;
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../models/app_lock_type.dart';
import '../models/budget.dart';
import '../models/budget_status.dart';
import '../models/category.dart';
import '../models/icon_type.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../services/auth_service.dart';
import '../services/security_service.dart';
import '../theme/app_icons.dart';

/// Single app-wide state holder (provided via `provider` at the app root).
/// Holds in-memory lists loaded from SQLite on [load]; every mutation writes
/// to SQLite first, then updates the in-memory list and calls
/// [notifyListeners]. There is no other state layer — new features extend
/// this repository.
class FinanceRepository extends ChangeNotifier {
  FinanceRepository({AppDatabase? appDatabase, SecurityService? securityService, AuthService? authService})
      : _appDatabase = appDatabase ?? AppDatabase.instance,
        _securityService = securityService ?? SecurityService(),
        _authService = authService ?? AuthService();

  final AppDatabase _appDatabase;
  final SecurityService _securityService;
  final AuthService _authService;

  List<Wallet> _wallets = [];
  List<Category> _categories = [];
  List<Transaction> _transactions = [];
  List<Budget> _budgets = [];

  /// True until the first [load] finishes. `main.dart` creates this
  /// repository with a fire-and-forget `..load()`, so screens render for a
  /// few frames before real data arrives — watching this flag lets them show
  /// a neutral loading state instead of a misleading "belum ada apa-apa"
  /// empty state on a cold start with real data already on disk (see UX-001).
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  /// Defaults to light on a fresh install; [toggleDarkMode] pins it to an
  /// explicit light/dark choice, mirroring the mockup's own
  /// override-vs-system-preference behavior. Persisted to the `settings`
  /// table so the choice survives app restarts.
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  static const _themeModeKey = 'theme_mode';

  Future<void> toggleDarkMode() async {
    final isCurrentlyDark = _themeMode == ThemeMode.dark ||
        (_themeMode == ThemeMode.system &&
            PlatformDispatcher.instance.platformBrightness == Brightness.dark);
    final newMode = isCurrentlyDark ? ThemeMode.light : ThemeMode.dark;
    _themeMode = newMode;
    notifyListeners();

    final db = await _appDatabase.database;
    await db.insert(
      'settings',
      // Uses the mode captured above, not the (possibly since-changed)
      // `_themeMode` field, so overlapping toggle calls each persist their
      // own intended value instead of racing on the shared field.
      {'key': _themeModeKey, 'value': newMode.name},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// App-lock (doc 4.11). `none` means the app opens straight to [AppShell];
  /// `pin`/`biometric` require [AppLockGate] to pass a PIN/biometric check
  /// first. Biometric mode still requires a PIN underneath as a fallback
  /// (device with no biometrics enrolled, or a failed biometric prompt).
  AppLockType _appLockType = AppLockType.none;
  AppLockType get appLockType => _appLockType;
  bool get appLockEnabled => _appLockType != AppLockType.none;

  static const _appLockTypeKey = 'app_lock_type';

  Future<void> enableAppLock(AppLockType type, {required String pin}) async {
    // The PIN write must succeed before the lock is considered active —
    // flipping the flag first could lock the user out with no PIN to
    // actually unlock with.
    await _securityService.setPin(pin);
    _appLockType = type;
    notifyListeners();

    final db = await _appDatabase.database;
    await db.insert(
      'settings',
      {'key': _appLockTypeKey, 'value': type.name},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Switches between `pin`/`biometric` without touching the stored PIN —
  /// both modes keep the same PIN as a fallback, so there's nothing to
  /// re-enter when just changing which one is primary. Use [enableAppLock]
  /// instead when there's no PIN set yet (app-lock was off).
  Future<void> setAppLockType(AppLockType type) async {
    assert(type != AppLockType.none, 'use disableAppLock() to turn off app lock');
    _appLockType = type;
    notifyListeners();

    final db = await _appDatabase.database;
    await db.insert(
      'settings',
      {'key': _appLockTypeKey, 'value': type.name},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> disableAppLock() async {
    await _securityService.clearPin();
    _appLockType = AppLockType.none;
    notifyListeners();

    final db = await _appDatabase.database;
    await db.insert(
      'settings',
      {'key': _appLockTypeKey, 'value': AppLockType.none.name},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> verifyPin(String pin) => _securityService.verifyPin(pin);

  Future<bool> isBiometricAvailable() => _securityService.isBiometricAvailable();

  Future<bool> authenticateWithBiometric() => _securityService.authenticateWithBiometric();

  /// Login is Google Sign-In (doc 4.10/6.1) — [AuthGate] shows [LoginScreen]
  /// instead of the app when this is false. Refreshed on [load] and after
  /// sign-in/sign-out via [refreshLoginState] so screens that already branch
  /// on it (e.g. the forgot-PIN warning) stay in sync without needing their
  /// own AuthService plumbing.
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;
  String? _userEmail;
  String? get userEmail => _userEmail;

  Future<void> refreshLoginState() async {
    final user = await _authService.currentUser;
    _isLoggedIn = user != null;
    _userEmail = user?.email;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    await refreshLoginState();
  }

  /// Local profile (name + avatar), editable offline; Phase 3 will add
  /// best-effort sync to a backend account on top of this.
  String _profileName = '';
  String get profileName => _profileName;

  String _profileAvatarIconValue = AppIcons.profileAvatar;
  String get profileAvatarIconValue => _profileAvatarIconValue;

  static const _profileNameKey = 'profile_name';
  static const _profileAvatarIconValueKey = 'profile_avatar_icon_value';

  Future<void> updateProfile({String? name, String? avatarIconValue}) async {
    if (name != null) _profileName = name;
    if (avatarIconValue != null) _profileAvatarIconValue = avatarIconValue;
    notifyListeners();

    final db = await _appDatabase.database;
    final batch = db.batch();
    if (name != null) {
      batch.insert('settings', {'key': _profileNameKey, 'value': name}, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    if (avatarIconValue != null) {
      batch.insert(
        'settings',
        {'key': _profileAvatarIconValueKey, 'value': avatarIconValue},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  List<Wallet> get wallets => List.unmodifiable(_wallets);
  List<Category> get categories => List.unmodifiable(_categories);
  List<Budget> get budgets => List.unmodifiable(_budgets);

  /// Active (non-deleted) transactions. Soft-deleted rows stay in
  /// [_transactions] for sync safety (doc 4.1/4.10) but are hidden here.
  List<Transaction> get transactions =>
      List.unmodifiable(_transactions.where((t) => !t.isDeleted));

  /// Includes soft-deleted rows — used by [SyncService] to push tombstones
  /// to the backend (doc 4.10) so a deletion on one device propagates to
  /// others instead of the row silently reappearing there.
  List<Transaction> get allTransactionsIncludingDeleted => List.unmodifiable(_transactions);

  Future<void> load() async {
    final db = await _appDatabase.database;

    final results = await Future.wait([
      db.query('wallets'),
      db.query('categories'),
      db.query('transactions'),
      db.query('budgets'),
      db.query('settings'),
    ]);
    final [walletRows, categoryRows, transactionRows, budgetRows, settingsRows] = results;

    _wallets = walletRows.map(Wallet.fromMap).toList();
    _categories = categoryRows.map(Category.fromMap).toList();
    _transactions = transactionRows.map(Transaction.fromMap).toList();
    _budgets = budgetRows.map(Budget.fromMap).toList();

    final settings = {for (final row in settingsRows) row['key'] as String: row['value'] as String};
    if (settings[_themeModeKey] case final value?) {
      _themeMode = ThemeMode.values.byName(value);
    }
    if (settings[_appLockTypeKey] case final value?) {
      _appLockType = AppLockType.fromName(value);
    }
    if (settings[_profileNameKey] case final value?) {
      _profileName = value;
    }
    if (settings[_profileAvatarIconValueKey] case final value?) {
      _profileAvatarIconValue = value;
    }

    await _syncBudgetPeriods();
    final user = await _authService.currentUser;
    _isLoggedIn = user != null;
    _userEmail = user?.email;
    _isLoading = false;
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

  /// Hard delete, mirroring [deleteCategory]/[deleteBudget] — wallets have no
  /// soft-delete column. Callers keep at least one wallet around (Dompet's
  /// delete flow refuses to remove the last one), mirroring the mockup.
  /// Callers should also keep a wallet from being deleted while any
  /// transaction still references it as [Transaction.walletId] or
  /// [Transaction.targetWalletId] (Dompet's delete flow checks [transactions]
  /// first), since [totalBalance]/[balanceOf] silently drop transactions
  /// whose wallet id no longer resolves — orphaning them instead of erroring.
  Future<void> deleteWallet(String walletId) async {
    final db = await _appDatabase.database;
    await db.delete('wallets', where: 'id = ?', whereArgs: [walletId]);
    _wallets = _wallets.where((w) => w.id != walletId).toList();
    notifyListeners();
  }

  Future<void> addCategory(Category category) async {
    final db = await _appDatabase.database;
    await db.insert('categories', category.toMap());
    _categories = [..._categories, category];
    notifyListeners();
  }

  Future<void> updateCategory(Category category) async {
    final db = await _appDatabase.database;
    await db.update('categories', category.toMap(), where: 'id = ?', whereArgs: [category.id]);
    _categories = [for (final c in _categories) if (c.id == category.id) category else c];
    notifyListeners();
  }

  /// Hard delete, mirroring [deleteBudget] — categories have no soft-delete
  /// column. Callers should keep a category from being deleted while a
  /// budget still references it (Kelola Kategori's delete flow checks
  /// [budgets] first) since [budgetStatuses] silently drops budgets whose
  /// category id no longer resolves.
  Future<void> deleteCategory(String categoryId) async {
    final db = await _appDatabase.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [categoryId]);
    _categories = _categories.where((c) => c.id != categoryId).toList();
    notifyListeners();
  }

  Future<void> addTransaction(Transaction transaction) async {
    // Local writes always start Pending (doc 4.10/7.2 per-transaction sync
    // status) — SyncService flips them to Synced after a successful push.
    // Rows written by SyncService itself go through AppDatabase.upsertRows
    // directly, bypassing this method, so this can't mis-flag pulled data.
    final pending = transaction.copyWith(syncStatus: SyncStatus.pending);
    final db = await _appDatabase.database;
    await db.insert('transactions', pending.toMap());
    _transactions = [..._transactions, pending];
    await _syncBudgetPeriods(newTransaction: pending);
    notifyListeners();
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final db = await _appDatabase.database;
    final updated = transaction.copyWith(updatedAt: DateTime.now(), syncStatus: SyncStatus.pending);
    await db.update('transactions', updated.toMap(), where: 'id = ?', whereArgs: [updated.id]);
    _transactions = [for (final t in _transactions) if (t.id == updated.id) updated else t];
    notifyListeners();
  }

  /// Soft delete (doc 4.1): marks the row deleted instead of removing it, so
  /// it stays safe for the future sync feature. [transactions] filters these
  /// out; the raw list above still contains them.
  Future<void> deleteTransaction(String transactionId) async {
    final existing = _transactions.firstWhere((t) => t.id == transactionId);
    final deleted = existing.copyWith(isDeleted: true, updatedAt: DateTime.now(), syncStatus: SyncStatus.pending);

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

  /// The timestamp a budget's period should start from, for the given
  /// [period]/[resetAnchor] as of [now] (defaults to [DateTime.now]) — the
  /// most recent monthly/weekly anchor occurrence, or `now` itself for Event
  /// (there's no calendar anchor to fall back to before the first trigger).
  /// Used both to seed a freshly-created budget's initial period and by
  /// [_syncBudgetPeriods] to detect when an existing budget has crossed into
  /// a new period.
  DateTime periodStartFor({required BudgetPeriod period, int? resetAnchor, DateTime? now}) {
    final effectiveNow = now ?? DateTime.now();
    switch (period) {
      case BudgetPeriod.monthly:
        return _mostRecentMonthlyAnchor(resetAnchor ?? 1, effectiveNow);
      case BudgetPeriod.weekly:
        return _mostRecentWeeklyAnchor(resetAnchor ?? DateTime.monday, effectiveNow);
      case BudgetPeriod.event:
        return effectiveNow;
    }
  }

  DateTime _mostRecentMonthlyAnchor(int anchorDay, DateTime now) {
    final daysInThisMonth = DateTime(now.year, now.month + 1, 0).day;
    final thisMonthAnchor = DateTime(now.year, now.month, anchorDay.clamp(1, daysInThisMonth));
    if (!thisMonthAnchor.isAfter(now)) return thisMonthAnchor;
    final prevMonth = DateTime(now.year, now.month - 1, 1);
    final daysInPrevMonth = DateTime(prevMonth.year, prevMonth.month + 1, 0).day;
    return DateTime(prevMonth.year, prevMonth.month, anchorDay.clamp(1, daysInPrevMonth));
  }

  DateTime _mostRecentWeeklyAnchor(int weekday, DateTime now) {
    final todayStart = DateTime(now.year, now.month, now.day);
    final diff = (todayStart.weekday - weekday) % 7;
    return todayStart.subtract(Duration(days: diff));
  }

  /// Advances any budget whose period has rolled over — monthly/weekly
  /// budgets are checked against the calendar every time this runs (called
  /// from [load] and after [addTransaction]); Event budgets only advance
  /// when [newTransaction] is a matching income transaction for their
  /// [Budget.triggerCategoryId] (doc 4.4). Mirrors [setBudget]'s
  /// upsert-then-notify shape but batches every changed row into one write.
  Future<void> _syncBudgetPeriods({Transaction? newTransaction}) async {
    final now = DateTime.now();
    final updates = <Budget>[];
    for (final budget in _budgets) {
      DateTime? newStart;
      if (budget.period == BudgetPeriod.event) {
        if (newTransaction != null &&
            !newTransaction.isDeleted &&
            newTransaction.type == TransactionType.income &&
            newTransaction.categoryId == budget.triggerCategoryId) {
          newStart = newTransaction.dateTime;
        }
      } else {
        final anchor = periodStartFor(period: budget.period, resetAnchor: budget.resetAnchor, now: now);
        if (anchor.isAfter(budget.currentPeriodStartedAt)) newStart = anchor;
      }
      if (newStart != null) {
        updates.add(budget.copyWith(currentPeriodStartedAt: newStart, updatedAt: now));
      }
    }
    if (updates.isEmpty) return;

    final db = await _appDatabase.database;
    final batch = db.batch();
    for (final budget in updates) {
      batch.update('budgets', budget.toMap(), where: 'id = ?', whereArgs: [budget.id]);
    }
    await batch.commit(noResult: true);

    final updatesById = {for (final budget in updates) budget.id: budget};
    _budgets = [for (final budget in _budgets) updatesById[budget.id] ?? budget];
  }

  /// Ends the current period early and starts a new one from now (doc 4.4's
  /// manual reset), regardless of [Budget.period] — usage recomputes to 0
  /// since no transactions can predate `now`.
  Future<void> resetBudgetNow(String budgetId) async {
    final now = DateTime.now();
    final existing = _budgets.firstWhere((b) => b.id == budgetId);
    final updated = existing.copyWith(currentPeriodStartedAt: now, updatedAt: now);

    final db = await _appDatabase.database;
    await db.update('budgets', updated.toMap(), where: 'id = ?', whereArgs: [budgetId]);
    _budgets = [for (final b in _budgets) if (b.id == budgetId) updated else b];
    notifyListeners();
  }

  /// Moves money between two wallets (doc 4.3): recorded as a single
  /// [TransactionType.transfer] row rather than a paired in/out transaction —
  /// see [balanceOf] for how both sides are applied. Reuses [addTransaction]
  /// so budget-period sync and persistence stay in one place.
  Future<void> addTransfer({
    required String fromWalletId,
    required String toWalletId,
    required int amount,
    String? note,
  }) {
    final now = DateTime.now();
    return addTransaction(Transaction(
      id: const Uuid().v4(),
      type: TransactionType.transfer,
      amount: amount,
      walletId: fromWalletId,
      targetWalletId: toWalletId,
      dateTime: now,
      note: note,
      createdAt: now,
      updatedAt: now,
    ));
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

  /// Amount spent against [budget]'s category since [Budget.currentPeriodStartedAt],
  /// computed on demand (doc 4.4/5.4) rather than tracked as a running total.
  int budgetUsage(Budget budget) {
    var used = 0;
    for (final t in transactions) {
      if (t.type == TransactionType.expense &&
          t.categoryId == budget.categoryId &&
          !t.dateTime.isBefore(budget.currentPeriodStartedAt)) {
        used += t.amount;
      }
    }
    return used;
  }

  /// Fills the app with ~3 months of realistic sample data for demoing —
  /// extra wallets, category budgets, and income/expense transactions
  /// written in the voice of an Indonesian household mom (doc 2.6). Wired to
  /// the "Generate Data Dummy" button in Pengaturan. Re-running it tops up
  /// with another batch of transactions but won't duplicate the extra
  /// wallets/budgets it already created.
  Future<void> generateDummyData() async {
    const uuid = Uuid();
    final random = Random();
    final now = DateTime.now();

    final categoriesByIconValue = {for (final c in _categories) c.iconValue: c};
    Category? categoryFor(String iconValue) => categoriesByIconValue[iconValue];

    final existingCash = _wallets.where((w) => w.type == WalletType.cash).firstOrNull;
    final existingBank = _wallets.where((w) => w.iconValue == 'wallet_bank').firstOrNull;
    final existingEWallet = _wallets.where((w) => w.iconValue == 'wallet_ewallet').firstOrNull;

    final cashWallet = existingCash ??
        Wallet(
          id: uuid.v4(),
          name: 'Dompet Tunai',
          type: WalletType.cash,
          color: '#F7C6D9',
          iconType: IconType.system,
          iconValue: 'wallet_cash',
          createdAt: now,
        );
    final bankWallet = existingBank ??
        Wallet(
          id: uuid.v4(),
          name: 'Bank BCA',
          type: WalletType.bank,
          color: '#DCD3F0',
          iconType: IconType.system,
          iconValue: 'wallet_bank',
          createdAt: now,
        );
    final eWallet = existingEWallet ??
        Wallet(
          id: uuid.v4(),
          name: 'GoPay',
          type: WalletType.eWallet,
          color: '#C4EBD9',
          iconType: IconType.system,
          iconValue: 'wallet_ewallet',
          createdAt: now,
        );

    final newWallets = [
      if (existingCash == null) cashWallet,
      if (existingBank == null) bankWallet,
      if (existingEWallet == null) eWallet,
    ];

    int randAmount(int min, int max) => min + random.nextInt(max - min + 1);
    String pick(List<String> notes) => notes[random.nextInt(notes.length)];

    const budgetLimits = {
      'category_kitchen': 1500000,
      'category_kids_snack': 300000,
      'category_school': 500000,
      'category_arisan': 250000,
      'category_bills': 600000,
      'category_health': 300000,
      'category_transport': 400000,
      'category_entertainment': 200000,
    };
    final newBudgets = <Budget>[
      for (final entry in budgetLimits.entries)
        if (categoryFor(entry.key) case final category?)
          if (!_budgets.any((b) => b.categoryId == category.id))
            Budget(
              id: uuid.v4(),
              categoryId: category.id,
              limitAmount: entry.value,
              // Default monthly/day-1 period — anchor usage at the start of
              // this month so the generated transactions below (which are
              // backdated through the month) actually count toward it.
              currentPeriodStartedAt: DateTime(now.year, now.month, 1),
              createdAt: now,
              updatedAt: now,
            ),
    ];

    const kitchenNotes = ['Belanja sayur & lauk di pasar', 'Beli beras & minyak', 'Belanja bulanan di minimarket', 'Beli ikan & ayam', 'Bumbu dapur habis'];
    const snackNotes = ['Jajan es krim buat anak', 'Beli susu & biskuit', 'Jajan sekolah', 'Snack kesukaan si kecil'];
    const transportNotes = ['Isi bensin motor', 'Ongkos ojek online', 'Bayar parkir', 'Servis motor rutin'];
    const billsNotes = ['Token listrik', 'Bayar air PDAM', 'Bayar WiFi', 'Iuran sampah & keamanan'];
    const healthNotes = ['Beli obat di apotek', 'Vitamin anak', 'Periksa ke dokter keluarga'];
    const entertainmentNotes = ['Nonton bareng keluarga', 'Jajan di luar pas weekend', 'Piknik keluarga'];
    const schoolNotes = ['Bayar SPP bulanan', 'Beli buku & alat tulis'];
    const arisanNotes = ['Setoran arisan RT', 'Arisan keluarga'];

    final newTransactions = <Transaction>[];

    for (var monthOffset = 2; monthOffset >= 0; monthOffset--) {
      final monthDate = DateTime(now.year, now.month - monthOffset, 1);
      final lastDay = DateTime(monthDate.year, monthDate.month + 1, 0).day;

      DateTime? dayInMonth(int day) {
        final date = DateTime(monthDate.year, monthDate.month, day.clamp(1, lastDay));
        return date.isAfter(now) ? null : date;
      }

      void addTx({
        required TransactionType type,
        required int amount,
        required String walletId,
        String? targetWalletId,
        String? categoryIconValue,
        required int day,
        String? note,
      }) {
        final date = dayInMonth(day);
        if (date == null) return;
        newTransactions.add(Transaction(
          id: uuid.v4(),
          type: type,
          amount: amount,
          walletId: walletId,
          targetWalletId: targetWalletId,
          categoryId: categoryIconValue == null ? null : categoryFor(categoryIconValue)?.id,
          dateTime: date,
          note: note,
          createdAt: date,
          updatedAt: date,
        ));
      }

      addTx(type: TransactionType.income, amount: 6000000, walletId: bankWallet.id, categoryIconValue: 'category_salary', day: 1, note: 'Gajian suami bulan ini');
      for (final day in [3, 10, 17, 24]) {
        addTx(type: TransactionType.income, amount: randAmount(500000, 750000), walletId: cashWallet.id, categoryIconValue: 'category_allowance', day: day, note: 'Uang belanja dari suami');
      }
      for (var i = 0; i < 2; i++) {
        addTx(type: TransactionType.income, amount: randAmount(150000, 400000), walletId: eWallet.id, categoryIconValue: 'category_side_business', day: randAmount(5, 25), note: 'Hasil jualan online');
      }

      addTx(type: TransactionType.transfer, amount: randAmount(500000, 1000000), walletId: bankWallet.id, targetWalletId: cashWallet.id, day: 2, note: 'Tarik tunai buat belanja');

      for (var i = 0; i < randAmount(10, 14); i++) {
        addTx(type: TransactionType.expense, amount: randAmount(30000, 150000), walletId: cashWallet.id, categoryIconValue: 'category_kitchen', day: randAmount(1, 28), note: pick(kitchenNotes));
      }
      for (var i = 0; i < randAmount(6, 9); i++) {
        addTx(
          type: TransactionType.expense,
          amount: randAmount(10000, 30000),
          walletId: random.nextBool() ? cashWallet.id : eWallet.id,
          categoryIconValue: 'category_kids_snack',
          day: randAmount(1, 28),
          note: pick(snackNotes),
        );
      }
      addTx(type: TransactionType.expense, amount: randAmount(300000, 500000), walletId: bankWallet.id, categoryIconValue: 'category_school', day: 5, note: pick(schoolNotes));
      addTx(type: TransactionType.expense, amount: randAmount(100000, 250000), walletId: cashWallet.id, categoryIconValue: 'category_arisan', day: 15, note: pick(arisanNotes));
      for (var i = 0; i < randAmount(2, 3); i++) {
        addTx(type: TransactionType.expense, amount: randAmount(100000, 400000), walletId: bankWallet.id, categoryIconValue: 'category_bills', day: randAmount(1, 28), note: pick(billsNotes));
      }
      if (random.nextBool()) {
        addTx(type: TransactionType.expense, amount: randAmount(50000, 300000), walletId: cashWallet.id, categoryIconValue: 'category_health', day: randAmount(1, 28), note: pick(healthNotes));
      }
      for (var i = 0; i < randAmount(6, 10); i++) {
        addTx(type: TransactionType.expense, amount: randAmount(10000, 50000), walletId: eWallet.id, categoryIconValue: 'category_transport', day: randAmount(1, 28), note: pick(transportNotes));
      }
      for (var i = 0; i < randAmount(1, 2); i++) {
        addTx(
          type: TransactionType.expense,
          amount: randAmount(50000, 200000),
          walletId: random.nextBool() ? cashWallet.id : eWallet.id,
          categoryIconValue: 'category_entertainment',
          day: randAmount(1, 28),
          note: pick(entertainmentNotes),
        );
      }
    }

    final db = await _appDatabase.database;
    final batch = db.batch();
    for (final wallet in newWallets) {
      batch.insert('wallets', wallet.toMap());
    }
    for (final budget in newBudgets) {
      batch.insert('budgets', budget.toMap());
    }
    for (final transaction in newTransactions) {
      batch.insert('transactions', transaction.toMap());
    }
    await batch.commit(noResult: true);

    _wallets = [..._wallets, ...newWallets];
    _budgets = [..._budgets, ...newBudgets];
    _transactions = [..._transactions, ...newTransactions];
    notifyListeners();
  }

  /// Wipes all wallets, categories, transactions, and budgets, then reseeds
  /// the default cash wallet and system categories — wired to the "Hapus
  /// Semua Data" action in Pengaturan. Leaves [themeMode] untouched since
  /// that's a device preference, not app data.
  Future<void> clearAllData() async {
    await _appDatabase.clearAllData();
    await load();
  }

  /// Every [Budget] paired with its category and this month's usage,
  /// sorted by usage percentage descending — shared by any screen that
  /// ranks/displays budget progress (Beranda, Rangkuman, Anggaran).
  List<BudgetStatus> get budgetStatuses {
    final statuses = <BudgetStatus>[];
    for (final budget in _budgets) {
      final category = _categories.where((c) => c.id == budget.categoryId).firstOrNull;
      if (category == null) continue;
      final used = budgetUsage(budget);
      final pct = budget.limitAmount == 0 ? 0 : (used * 100 / budget.limitAmount).round();
      final triggerCategory =
          budget.triggerCategoryId == null ? null : _categories.where((c) => c.id == budget.triggerCategoryId).firstOrNull;
      statuses.add(BudgetStatus(category: category, budget: budget, used: used, pct: pct, triggerCategory: triggerCategory));
    }
    statuses.sort((a, b) => b.pct.compareTo(a.pct));
    return List.unmodifiable(statuses);
  }
}
