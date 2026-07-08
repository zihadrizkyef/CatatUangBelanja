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
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const _dbName = 'catat_uang_belanja.db';
  static const _dbVersion = 2;

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
        limit_amount INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    await _createSettingsTable(db);

    await _seed(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createSettingsTable(db);
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

  Future<void> _seed(DatabaseExecutor db) async {
    const uuid = Uuid();
    final now = DateTime.now();

    final cashWallet = Wallet(
      id: uuid.v4(),
      name: 'Dompet Tunai',
      type: WalletType.cash,
      color: '#F7C6D9',
      iconType: IconType.system,
      iconValue: 'wallet_cash',
      createdAt: now,
    );
    await db.insert('wallets', cashWallet.toMap());

    for (final category in _systemCategories(uuid)) {
      await db.insert('categories', category.toMap());
    }
  }

  /// Household categories per doc 2.7.
  List<Category> _systemCategories(Uuid uuid) {
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
          id: uuid.v4(),
          name: name,
          type: CategoryType.expense,
          color: color,
          iconType: IconType.system,
          iconValue: iconValue,
          isSystem: true,
        ),
      for (final (name, iconValue, color) in incomeCategories)
        Category(
          id: uuid.v4(),
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
