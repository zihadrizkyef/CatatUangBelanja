import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:catat_uang_belanja/db/app_database.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Start from a clean file so seeding is deterministic across test runs.
    final dbPath = join(await databaseFactory.getDatabasesPath(), 'catat_uang_belanja.db');
    final file = File(dbPath);
    if (await file.exists()) {
      await file.delete();
    }
  });

  test('AppDatabase creates schema and seeds default wallets + categories', () async {
    final db = await AppDatabase.instance.database;

    // 4 default wallets (doc 4.2 starter set): Dompet Tunai, Rekening Bank,
    // E-Wallet, Tabungan.
    final wallets = await db.query('wallets');
    expect(wallets.length, 4);
    expect(wallets.first['name'], 'Dompet Tunai');

    final categories = await db.query('categories');
    expect(categories.length, 13);
    expect(categories.every((row) => row['is_system'] == 1), true);

    final expenseCategories = await db.query('categories', where: 'type = ?', whereArgs: ['expense']);
    expect(expenseCategories.length, 8);

    final incomeCategories = await db.query('categories', where: 'type = ?', whereArgs: ['income']);
    expect(incomeCategories.length, 5);
  });

  test('AppDatabase is a singleton reusing the same open connection', () async {
    final first = await AppDatabase.instance.database;
    final second = await AppDatabase.instance.database;
    expect(identical(first, second), true);
  });
}
