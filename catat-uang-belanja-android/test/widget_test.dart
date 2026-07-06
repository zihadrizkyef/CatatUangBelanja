import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:catat_uang_belanja/main.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // pumpWidget(MyApp()) below bypasses main(), so this test must repeat the
    // same locale-data init main() does before runApp.
    await initializeDateFormatting('id_ID', null);

    // Start from a clean on-disk database so the empty-state UI below is
    // deterministic across test runs (per project testing notes).
    final dbPath = join(await databaseFactory.getDatabasesPath(), 'catat_uang_belanja.db');
    final file = File(dbPath);
    if (await file.exists()) {
      await file.delete();
    }
  });

  testWidgets('App loads, shows bottom nav, and seeded empty-state Beranda', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const MyApp());
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Dompet'), findsOneWidget);
    expect(find.text('Rangkuman'), findsOneWidget);
    expect(find.text('Pengaturan'), findsOneWidget);
    expect(find.text('Belum ada transaksi, Bun. Yuk catat yang pertama.'), findsOneWidget);
  });

  testWidgets('Tapping the FAB opens TransactionSheet and can save a transaction', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const MyApp());
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Catat transaksi'));
    await tester.pumpAndSettle();

    expect(find.text('Tambah Pengeluaran'), findsOneWidget);

    await tester.ensureVisible(find.text('Belanja Dapur'));
    await tester.tap(find.text('Belanja Dapur'));
    await tester.pumpAndSettle();
    for (final digit in ['2', '5', '0', '0', '0']) {
      await tester.ensureVisible(find.text(digit));
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await tester.ensureVisible(find.text('✓'));
    await tester.tap(find.text('✓'));
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    expect(find.text('Tambah Pengeluaran'), findsNothing);
    expect(find.text('Belum ada transaksi, Bun. Yuk catat yang pertama.'), findsNothing);
  });

  testWidgets('Tapping bottom nav switches tabs', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const MyApp());
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();

    await tester.tap(find.text('Dompet'));
    await tester.pumpAndSettle();
    expect(find.text('Dompet Tunai'), findsOneWidget);
  });
}
