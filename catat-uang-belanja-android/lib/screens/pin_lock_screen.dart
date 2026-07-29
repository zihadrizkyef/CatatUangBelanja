import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_lock_type.dart';
import '../repositories/finance_repository.dart';
import 'pin_lock_screen_view.dart';

/// Full-screen app-lock gate (doc 4.11) — no dismiss gesture, blocks the
/// whole app until the PIN (or biometric, with PIN fallback) is verified.
/// Built by [AppLockGate] rather than pushed via [Navigator], so it reports
/// success through [onUnlocked] instead of popping itself. Reads
/// [FinanceRepository] for PIN/biometric verification; hands the rest to
/// [PinLockScreenView].
class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key, required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _digits = '';
  String? _errorText;
  bool _autoPromptDone = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoTriggerBiometricOnce());
  }

  Future<void> _autoTriggerBiometricOnce() async {
    if (_autoPromptDone) return;
    _autoPromptDone = true;
    if (context.read<FinanceRepository>().appLockType != AppLockType.biometric) return;
    await _promptBiometric();
  }

  Future<void> _promptBiometric() async {
    final repository = context.read<FinanceRepository>();
    final success = await repository.authenticateWithBiometric();
    if (success && mounted) widget.onUnlocked();
  }

  void _onKeyTap(String key) {
    if (_isVerifying) return;
    if (key == '⌫') {
      if (_digits.isNotEmpty) setState(() => _digits = _digits.substring(0, _digits.length - 1));
      return;
    }
    if (key == '✓') {
      if (_digits.length == 6) _verify();
      return;
    }
    if (_digits.length >= 6) return;
    setState(() {
      _digits += key;
      _errorText = null;
    });
    if (_digits.length == 6) _verify();
  }

  Future<void> _verify() async {
    setState(() => _isVerifying = true);
    final repository = context.read<FinanceRepository>();
    final correct = await repository.verifyPin(_digits);
    if (!mounted) return;
    if (correct) {
      widget.onUnlocked();
      return;
    }
    setState(() {
      _isVerifying = false;
      _errorText = 'PIN salah, coba lagi ya, Bun';
      _digits = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<FinanceRepository>();

    return PopScope(
      canPop: false,
      child: PinLockScreenView(
        isBiometric: repository.appLockType == AppLockType.biometric,
        digitsEntered: _digits.length,
        isVerifying: _isVerifying,
        errorText: _errorText,
        // "Lupa PIN" needs an account to re-verify against (Phase 3's email
        // OTP) — with no login yet, there's no recovery path to offer.
        showForgotPin: repository.isLoggedIn,
        onKeyTap: _onKeyTap,
        onRetryBiometric: _promptBiometric,
        onTapForgotPin: () {},
      ),
    );
  }
}
