import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_lock_type.dart';
import '../repositories/finance_repository.dart';
import 'pin_setup_sheet_view.dart';

enum PinSetupStage { enter, confirm }

/// Bottom sheet container for setting/changing the app-lock PIN (doc 4.11):
/// enter 6 digits, then confirm the same 6 digits. On a match, persists via
/// [FinanceRepository.enableAppLock] and closes; on a mismatch, shows an
/// error and restarts from the enter stage. Reads [FinanceRepository] and
/// wires up [Navigator] dismissal; hands the rest to [PinSetupSheetView].
class PinSetupSheet extends StatefulWidget {
  const PinSetupSheet({super.key, required this.lockType});

  /// Which [AppLockType] to activate once the PIN is confirmed — `pin` for
  /// PIN-only lock, `biometric` when the PIN is being set as the fallback
  /// for a biometric lock.
  final AppLockType lockType;

  @override
  State<PinSetupSheet> createState() => _PinSetupSheetState();
}

class _PinSetupSheetState extends State<PinSetupSheet> {
  PinSetupStage _stage = PinSetupStage.enter;
  String _digits = '';
  String? _firstPin;
  String? _errorText;

  void _onKeyTap(String key) {
    if (key == '⌫') {
      if (_digits.isNotEmpty) setState(() => _digits = _digits.substring(0, _digits.length - 1));
      return;
    }
    if (key == '✓') {
      if (_digits.length == 6) _submitStage();
      return;
    }
    if (_digits.length >= 6) return;
    setState(() {
      _digits += key;
      _errorText = null;
    });
    if (_digits.length == 6) _submitStage();
  }

  Future<void> _submitStage() async {
    if (_stage == PinSetupStage.enter) {
      setState(() {
        _firstPin = _digits;
        _digits = '';
        _stage = PinSetupStage.confirm;
      });
      return;
    }

    if (_digits != _firstPin) {
      setState(() {
        _errorText = 'PIN tidak sama, coba lagi ya, Bun';
        _digits = '';
        _firstPin = null;
        _stage = PinSetupStage.enter;
      });
      return;
    }

    final repository = context.read<FinanceRepository>();
    await repository.enableAppLock(widget.lockType, pin: _digits);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<FinanceRepository>().isLoggedIn;

    return PinSetupSheetView(
      stage: _stage,
      digitsEntered: _digits.length,
      errorText: _errorText,
      showForgotPinWarning: !isLoggedIn,
      onKeyTap: _onKeyTap,
      onClose: () => Navigator.of(context).pop(),
    );
  }
}
