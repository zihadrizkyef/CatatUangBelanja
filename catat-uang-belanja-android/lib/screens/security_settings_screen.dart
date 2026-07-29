import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_lock_type.dart';
import '../repositories/finance_repository.dart';
import '../utils/snackbar.dart';
import 'pin_setup_sheet.dart';
import 'security_settings_view.dart';

/// Pengaturan > Keamanan screen (doc 4.11): app-lock master toggle, PIN vs
/// biometric choice, and "Ubah PIN" — pushed via [Navigator] from
/// Pengaturan's "Keamanan" row. Reads [FinanceRepository] and wires up the
/// [PinSetupSheet]/toast/[Navigator] actions; hands the rest to
/// [SecuritySettingsView].
class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricAvailability();
  }

  Future<void> _loadBiometricAvailability() async {
    final available = await context.read<FinanceRepository>().isBiometricAvailable();
    if (mounted) setState(() => _biometricAvailable = available);
  }

  void _openPinSetup(AppLockType lockType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PinSetupSheet(lockType: lockType),
    );
  }

  Future<void> _onToggleAppLock(bool enabled) async {
    if (enabled) {
      _openPinSetup(AppLockType.pin);
      return;
    }
    await context.read<FinanceRepository>().disableAppLock();
  }

  Future<void> _onSelectLockType(AppLockType type) async {
    if (type == AppLockType.biometric && !_biometricAvailable) {
      showSnackBarMessage(context, 'Belum ada sidik jari/Face ID yang terdaftar di HP ini, Bun');
      return;
    }
    await context.read<FinanceRepository>().setAppLockType(type);
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<FinanceRepository>();

    return SecuritySettingsView(
      appLockEnabled: repository.appLockEnabled,
      appLockType: repository.appLockType,
      biometricAvailable: _biometricAvailable,
      onToggleAppLock: _onToggleAppLock,
      onSelectLockType: _onSelectLockType,
      onTapChangePin: () => _openPinSetup(
        repository.appLockType == AppLockType.none ? AppLockType.pin : repository.appLockType,
      ),
      onTapBack: () => Navigator.of(context).pop(),
    );
  }
}
