import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

import 'repositories/finance_repository.dart';
import 'screens/app_shell.dart';
import 'services/auth_service.dart';
import 'services/jago_service.dart';
import 'services/sync_service.dart';
import 'theme/app_theme.dart';
import 'widgets/app_lock_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // sqflite only works natively on Android/iOS — wire up the FFI backends
  // for desktop/web before touching any database. Preserve this branching
  // when editing databaseFactory, or desktop/web builds hang with no error.
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  await initializeDateFormatting('id_ID', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FinanceRepository()..load()),
        // Shared between SyncService and JagoService below — both may call
        // AuthService.ensureInitialized(), which wraps a one-time (per app
        // lifetime, on web) GoogleSignIn.instance.initialize() call; two
        // separate AuthService instances would each try to memoize that
        // independently and risk calling it twice.
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<JagoService>(create: (context) => JagoService(authService: context.read<AuthService>())),
        ChangeNotifierProxyProvider<FinanceRepository, SyncService>(
          create: (context) => SyncService(
            repository: context.read<FinanceRepository>(),
            authService: context.read<AuthService>(),
            jagoService: context.read<JagoService>(),
          ),
          // FinanceRepository is created once for the app's lifetime, so the
          // proxy update just keeps SyncService pointed at the same instance
          // rather than needing to react to a changing one.
          update: (context, repository, previous) =>
              previous ??
              SyncService(
                repository: repository,
                authService: context.read<AuthService>(),
                jagoService: context.read<JagoService>(),
              ),
        ),
      ],
      child: Builder(
        builder: (context) {
          final themeMode = context.watch<FinanceRepository>().themeMode;
          return MaterialApp(
            title: 'Catat Uang Belanja',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            // Login is optional (doc 8's offline-first requirement takes
            // priority — the whole app must work with zero account, see
            // LoginScreen's real entry point: Pengaturan's "Masuk dengan
            // Google" action, not a startup gate).
            home: const AppLockGate(child: AppShell()),
          );
        },
      ),
    );
  }
}
