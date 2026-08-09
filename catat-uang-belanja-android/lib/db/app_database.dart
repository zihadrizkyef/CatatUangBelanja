import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart';
import '../models/icon_type.dart';
import '../models/wallet.dart';

/// Singleton wrapping the raw sqflite [Database]. Schema is created by hand
/// via CREATE TABLE (no migration framework) — bump [_dbVersion] and add
/// upgrade steps in [_onUpgrade] when the schema changes.
///
/// Platform note: the actual [databaseFactory] implementation (native
/// sqflite vs sqflite_common_ffi vs sqflite_common_ffi_web) is selected in
/// main() before runApp — this class only opens a database through whatever
/// factory is already installed.
class AppDatabase {
  AppDatabase._({String? dbName}) : _dbName = dbName ?? _defaultDbName;

  static final AppDatabase instance = AppDatabase._();

  /// A separate, non-singleton instance backed by its own db file — lets a
  /// test isolate itself from [instance] (and from other test files running
  /// as concurrent processes under `flutter test`, all of which would
  /// otherwise fight over the same shared on-disk file).
  factory AppDatabase.forTesting(String dbName) => AppDatabase._(dbName: dbName);

  static const _defaultDbName = 'catat_uang_belanja.db';
  static const _dbVersion = 5;

  /// Fixed namespace for deriving stable, deterministic IDs (UUID v5) for
  /// system wallets/categories from their `iconValue` key — see
  /// [_systemId]. Any valid UUID works as a v5 namespace; this one is just
  /// arbitrary and specific to this app.
  static const _systemIdNamespace = 'a3b6e9f0-9b1a-4e3a-8b0e-6f7c9d2a1b4c';

  /// A system wallet/category (e.g. "Belanja Dapur") must resolve to the
  /// *same* id every time it's seeded — on first install, after "Hapus
  /// Semua Data", and on every other device/reinstall — otherwise
  /// [SyncService]'s push-in-full-each-time strategy treats each reseed as
  /// brand new rows and duplicates pile up both locally (via pull) and on
  /// the backend. `uuid.v4()` (random) can't guarantee that; a name-based
  /// v5 UUID keyed on the already-unique `iconValue` can.
  static String _systemId(String iconValue) =>
      const Uuid().v5(_systemIdNamespace, iconValue);

  final String _dbName;

  Database? _database;

  Future<Database> get database async {
    _database ??= await _open();
    return _database!;
  }

  Future<Database> _open() async {
    // getDatabasesPath() isn't supported by databaseFactoryFfiWeb (browsers
    // have no filesystem) — the web factory just wants a bare db name.
    final dbPath =
        kIsWeb ? _dbName : join(await databaseFactory.getDatabasesPath(), _dbName);
    return databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE wallets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        color TEXT NOT NULL,
        icon_type TEXT NOT NULL,
        icon_value TEXT NOT NULL,
        is_archived INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        color TEXT NOT NULL,
        icon_type TEXT NOT NULL,
        icon_value TEXT NOT NULL,
        is_system INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        amount INTEGER NOT NULL,
        wallet_id TEXT NOT NULL,
        target_wallet_id TEXT,
        category_id TEXT,
        date_time TEXT NOT NULL,
        note TEXT,
        attachment_url TEXT,
        recurring_id TEXT,
        is_deleted INTEGER NOT NULL DEFAULT 0,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        source TEXT NOT NULL DEFAULT 'manual',
        external_id TEXT,
        FOREIGN KEY (wallet_id) REFERENCES wallets (id),
        FOREIGN KEY (target_wallet_id) REFERENCES wallets (id),
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id TEXT PRIMARY KEY,
        category_id TEXT NOT NULL,
        period TEXT NOT NULL DEFAULT 'monthly',
        reset_anchor INTEGER,
        trigger_category_id TEXT,
        limit_amount INTEGER NOT NULL,
        current_period_started_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id),
        FOREIGN KEY (trigger_category_id) REFERENCES categories (id)
      )
    ''');

    await _createSettingsTable(db);

    await _seed(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createSettingsTable(db);
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE budgets ADD COLUMN reset_anchor INTEGER');
      await db.execute('ALTER TABLE budgets ADD COLUMN trigger_category_id TEXT');
      await db.execute('ALTER TABLE budgets ADD COLUMN current_period_started_at TEXT');
      // Existing budgets predate periods entirely — treat them as monthly,
      // resetting on the 1st, with the current period starting this month.
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
      await db.update('budgets', {'reset_anchor': 1, 'current_period_started_at': startOfMonth});
    }
    if (oldVersion < 4) {
      await _dedupeSystemEntities(db, 'wallets', _systemWalletIconValues, [
        'transactions.wallet_id',
        'transactions.target_wallet_id',
      ]);
      await _dedupeSystemEntities(db, 'categories', _systemCategoryIconValues, [
        'transactions.category_id',
        'budgets.category_id',
        'budgets.trigger_category_id',
      ]);
    }
    if (oldVersion < 5) {
      // Bank Jago email sync (integrasi-jago) — every existing row is a
      // manual entry by definition, matching the column default.
      await db.execute("ALTER TABLE transactions ADD COLUMN source TEXT NOT NULL DEFAULT 'manual'");
      await db.execute('ALTER TABLE transactions ADD COLUMN external_id TEXT');
    }
  }

  static const _systemWalletIconValues = ['wallet_cash', 'wallet_bank', 'wallet_ewallet', 'wallet_savings'];
  static const _systemCategoryIconValues = [
    'category_kitchen',
    'category_kids_snack',
    'category_school',
    'category_arisan',
    'category_bills',
    'category_health',
    'category_transport',
    'category_entertainment',
    'category_salary',
    'category_allowance',
    'category_side_business',
    'category_bonus',
    'category_other',
  ];

  /// Migration for the switch from random (`uuid.v4()`) to deterministic
  /// (`_systemId`, keyed on `icon_value`) ids for system wallets/categories
  /// (doc 2.7) — see [_systemId] for why. Existing installs may have
  /// accumulated duplicate rows per `icon_value` from repeated reseeds
  /// (fresh install, "Hapus Semua Data") each generating a new random id
  /// that a full-state sync push then re-uploaded as a "new" entity. This
  /// collapses every row sharing an `icon_value` in [table] down to one,
  /// repointing the given `table.column` foreign-key references (e.g.
  /// `transactions.wallet_id`) from the removed duplicates to the survivor,
  /// which is re-keyed to the new deterministic id so this device's rows
  /// match what every other device/reseed will compute from now on.
  Future<void> _dedupeSystemEntities(
    Database db,
    String table,
    List<String> iconValues,
    List<String> referencingColumns,
  ) async {
    for (final iconValue in iconValues) {
      final rows = await db.query(table, where: 'icon_value = ?', whereArgs: [iconValue]);
      if (rows.isEmpty) continue;

      final canonicalId = _systemId(iconValue);
      final staleIds = [for (final row in rows) row['id'] as String].where((id) => id != canonicalId);

      for (final staleId in staleIds) {
        for (final referencingColumn in referencingColumns) {
          final parts = referencingColumn.split('.');
          await db.update(
            parts[0],
            {parts[1]: canonicalId},
            where: '${parts[1]} = ?',
            whereArgs: [staleId],
          );
        }
      }

      final representative = Map<String, Object?>.from(rows.first)..['id'] = canonicalId;
      await db.delete(table, where: 'icon_value = ?', whereArgs: [iconValue]);
      await db.insert(table, representative);
    }
  }

  /// Simple key-value store for app-wide preferences (e.g. `theme_mode`) that
  /// don't warrant their own typed table.
  Future<void> _createSettingsTable(Database db) async {
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  /// Wipes wallets/categories/transactions/budgets and reseeds the default
  /// cash wallet + system categories, all inside one transaction so a crash
  /// mid-wipe can't leave the app with no wallets and no reseed. Leaves the
  /// `settings` table (e.g. theme mode) alone — that's a device preference,
  /// not app data.
  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('transactions');
      await txn.delete('budgets');
      await txn.delete('categories');
      await txn.delete('wallets');
      await _seed(txn);
    });
  }

  /// Upserts rows pulled from the backend (doc 4.10) into [table] — each
  /// [rows] entry must already be shaped like [Wallet.toMap]/etc. (same
  /// snake_case columns the local schema uses), which is exactly the wire
  /// format `ApiClient.pull` returns. Used only by [SyncService].
  Future<void> upsertRows(String table, List<Map<String, Object?>> rows) async {
    final db = await database;
    await db.transaction((txn) async {
      for (final row in rows) {
        await txn.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> _seed(DatabaseExecutor db) async {
    final now = DateTime.now();

    for (final wallet in _systemWallets(now)) {
      await db.insert('wallets', wallet.toMap());
    }

    for (final category in _systemCategories()) {
      await db.insert('categories', category.toMap());
    }
  }

  /// Default multi-wallet starter set (doc 4.2 examples) so a new user sees
  /// more than just cash on first run.
  List<Wallet> _systemWallets(DateTime now) {
    const wallets = [
      ('Dompet Tunai', WalletType.cash, 'wallet_cash', '#F7C6D9'),
      ('Rekening Bank', WalletType.bank, 'wallet_bank', '#DCD3F0'),
      ('E-Wallet', WalletType.eWallet, 'wallet_ewallet', '#C4EBD9'),
      ('Tabungan', WalletType.savings, 'wallet_savings', '#FBD8B5'),
    ];

    return [
      for (final (name, type, iconValue, color) in wallets)
        Wallet(
          id: _systemId(iconValue),
          name: name,
          type: type,
          color: color,
          iconType: IconType.system,
          iconValue: iconValue,
          createdAt: now,
        ),
    ];
  }

  /// Household categories per doc 2.7.
  List<Category> _systemCategories() {
    const expenseCategories = [
      ('Belanja Dapur', 'category_kitchen', '#FBD8B5'),
      ('Jajan Anak', 'category_kids_snack', '#F7C6D9'),
      ('Sekolah Anak', 'category_school', '#DCD3F0'),
      ('Arisan', 'category_arisan', '#C4EBD9'),
      ('Tagihan Rumah', 'category_bills', '#FDF3E3'),
      ('Kesehatan Keluarga', 'category_health', '#F7C6D9'),
      ('Transportasi', 'category_transport', '#FBD8B5'),
      ('Hiburan Keluarga', 'category_entertainment', '#DCD3F0'),
    ];
    const incomeCategories = [
      ('Gaji', 'category_salary', '#C4EBD9'),
      ('Uang Belanja dari Suami', 'category_allowance', '#F7C6D9'),
      ('Hasil Jualan/Usaha Sampingan', 'category_side_business', '#FBD8B5'),
      ('Bonus', 'category_bonus', '#DCD3F0'),
      ('Lainnya', 'category_other', '#FDF3E3'),
    ];

    return [
      for (final (name, iconValue, color) in expenseCategories)
        Category(
          id: _systemId(iconValue),
          name: name,
          type: CategoryType.expense,
          color: color,
          iconType: IconType.system,
          iconValue: iconValue,
          isSystem: true,
        ),
      for (final (name, iconValue, color) in incomeCategories)
        Category(
          id: _systemId(iconValue),
          name: name,
          type: CategoryType.income,
          color: color,
          iconType: IconType.system,
          iconValue: iconValue,
          isSystem: true,
        ),
    ];
  }
}
