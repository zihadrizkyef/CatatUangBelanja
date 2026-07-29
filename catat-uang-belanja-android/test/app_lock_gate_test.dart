import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:catat_uang_belanja/db/app_database.dart';
import 'package:catat_uang_belanja/models/app_lock_type.dart';
import 'package:catat_uang_belanja/repositories/finance_repository.dart';
import 'package:catat_uang_belanja/services/secure_key_value_store.dart';
import 'package:catat_uang_belanja/services/security_service.dart';
import 'package:catat_uang_belanja/widgets/app_lock_gate.dart';

class _InMemorySecureStore implements SecureKeyValueStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);
}

void main() {
  late FinanceRepository repository;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // A dedicated db file, not the shared `catat_uang_belanja.db` other test
    // files use — those run as concurrent processes under `flutter test`,
    // and this test opening/writing the shared file at the same time as
    // another file's setUpAll deletes it causes "file in use" failures.
    final dbPath = join(await databaseFactory.getDatabasesPath(), 'app_lock_gate_test.db');
    final file = File(dbPath);
    if (await file.exists()) {
      await file.delete();
    }
  });

  setUp(() async {
    repository = FinanceRepository(
      appDatabase: AppDatabase.forTesting('app_lock_gate_test.db'),
      securityService: SecurityService(secureStorage: _InMemorySecureStore()),
    );
    await repository.load();
    // Isolate each test from app-lock state left by an earlier test in this
    // same file (the dedicated db file above is only wiped once, in
    // setUpAll, not between individual tests).
    await repository.disableAppLock();
  });

  Widget buildHarness() {
    return ChangeNotifierProvider<FinanceRepository>.value(
      value: repository,
      child: const MaterialApp(
        home: AppLockGate(child: Scaffold(body: Center(child: Text('Konten Aplikasi')))),
      ),
    );
  }

  testWidgets('shows the child directly when app-lock is off', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(buildHarness());
      await Future.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    expect(find.text('Konten Aplikasi'), findsOneWidget);
    expect(find.text('Aplikasi Terkunci'), findsNothing);
  });

  testWidgets('locks on cold start when app-lock is enabled, unlocks with the correct PIN', (tester) async {
    await tester.runAsync(() async {
      await repository.enableAppLock(AppLockType.pin, pin: '135790');
    });

    await tester.runAsync(() async {
      await tester.pumpWidget(buildHarness());
      await Future.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    expect(find.text('Aplikasi Terkunci'), findsOneWidget);
    expect(find.text('Konten Aplikasi'), findsNothing);

    for (final digit in ['1', '3', '5', '7', '9']) {
      await tester.ensureVisible(find.text(digit));
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await tester.ensureVisible(find.text('0'));
    await tester.runAsync(() async {
      await tester.tap(find.text('0')); // 6th digit triggers verification.
      await Future.delayed(const Duration(seconds: 2));
    });
    await tester.pumpAndSettle();

    expect(find.text('Konten Aplikasi'), findsOneWidget);
    expect(find.text('Aplikasi Terkunci'), findsNothing);
  });

  testWidgets('rejects the wrong PIN and stays locked', (tester) async {
    await tester.runAsync(() async {
      await repository.enableAppLock(AppLockType.pin, pin: '135790');
    });

    await tester.runAsync(() async {
      await tester.pumpWidget(buildHarness());
      await Future.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    for (final digit in ['0', '0', '0', '0', '0']) {
      await tester.ensureVisible(find.text(digit));
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await tester.ensureVisible(find.text('1'));
    await tester.runAsync(() async {
      await tester.tap(find.text('1'));
      await Future.delayed(const Duration(seconds: 2));
    });
    await tester.pumpAndSettle();

    expect(find.text('PIN salah, coba lagi ya, Bun'), findsOneWidget);
    expect(find.text('Konten Aplikasi'), findsNothing);
  });
}
