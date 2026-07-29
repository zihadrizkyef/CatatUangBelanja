import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_lock_type.dart';
import '../repositories/finance_repository.dart';
import '../screens/pin_lock_screen.dart';

/// Wraps [child] (the real app, i.e. `AppShell`) with the app-lock gate (doc
/// 4.11): shows [PinLockScreen] instead of [child] on cold start (once
/// loading finishes, if app-lock is enabled) and again whenever the app
/// resumes from the background. A plain [WidgetsBindingObserver] — there's
/// no router in this app to hook a route-level guard into instead.
class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  bool _locked = false;
  bool _hasEvaluatedInitialLock = false;

  // Only `paused` means the app was actually backgrounded. `inactive` alone
  // (a permission dialog, the biometric system prompt, an image picker,
  // a share sheet, the notification shade) also produces a `resumed` right
  // after it — locking on every `resumed` would re-lock the app mid-flow
  // even though the user never left it.
  bool _wasPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _wasPaused = true;
      return;
    }
    if (state != AppLifecycleState.resumed) return;
    if (!_wasPaused) return;
    _wasPaused = false;
    final repository = context.read<FinanceRepository>();
    if (repository.appLockType != AppLockType.none && !_locked) {
      setState(() => _locked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<FinanceRepository>();

    // Cold start: lock as soon as loading finishes, once, if app-lock is
    // enabled — evaluated here rather than initState since `load()` is async
    // and appLockType isn't known until the first data arrives. Mutating the
    // field directly (no setState) is safe: this build pass already reflects
    // it below, and it only ever flips once per cold start.
    if (!_hasEvaluatedInitialLock && !repository.isLoading) {
      _hasEvaluatedInitialLock = true;
      if (repository.appLockType != AppLockType.none) {
        _locked = true;
      }
    }

    if (_locked) {
      return PinLockScreen(onUnlocked: () => setState(() => _locked = false));
    }
    return widget.child;
  }
}
