import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repositories/finance_repository.dart';
import '../services/jago_service.dart';
import '../theme/app_theme.dart';
import '../utils/snackbar.dart';
import 'jago_settings_view.dart';

/// Pengaturan > Bank Jago screen: connects the Bank Jago email sync
/// (integrasi-jago) via [JagoService], or shows/disconnects an existing
/// connection. Named Kantong (Tabungan, Modal Bisnis, dst.) auto-match by
/// name and need no picker — only the nameless "Kantong Terhubung" (which
/// handles QRIS/card/transfer/top-up/withdrawal) is picked here, from
/// wallets Zihad already created himself. Reads [JagoService]/
/// [FinanceRepository]; hands the rest to [JagoSettingsView].
class JagoSettingsScreen extends StatefulWidget {
  const JagoSettingsScreen({super.key});

  @override
  State<JagoSettingsScreen> createState() => _JagoSettingsScreenState();
}

class _JagoSettingsScreenState extends State<JagoSettingsScreen> {
  bool _loading = true;
  bool _busy = false;
  JagoStatus _status = JagoStatus.disconnected;
  int _pickerIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  void _cycleWallet(int walletCount) {
    if (walletCount == 0) return;
    setState(() => _pickerIndex = (_pickerIndex + 1) % walletCount);
  }

  Future<void> _loadStatus() async {
    final status = await context.read<JagoService>().fetchStatus();
    if (mounted) {
      setState(() {
        _status = status;
        _loading = false;
      });
    }
  }

  Future<void> _connect(String connectedWalletId) async {
    setState(() => _busy = true);
    try {
      await context.read<JagoService>().connect(connectedWalletId);
      if (!mounted) return;
      showSnackBarMessage(context, 'Bank Jago terhubung! Sinkron mulai dari sekarang, Bun ✨');
      await _loadStatus();
    } catch (err) {
      if (mounted) showSnackBarMessage(context, _errorMessage(err));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Putuskan Bank Jago?', style: AppTheme.heading(fontSize: 18)),
        content: Text(
          'Transaksi yang sudah masuk tetap tersimpan — hanya sinkron otomatis dari email yang berhenti, Bun.',
          style: AppTheme.body(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Ya, Putuskan')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    await context.read<JagoService>().disconnect();
    await _loadStatus();
    if (mounted) setState(() => _busy = false);
  }

  String _errorMessage(Object err) => err is StateError ? err.message : 'Gagal menghubungkan Bank Jago, coba lagi ya, Bun.';

  @override
  Widget build(BuildContext context) {
    final wallets = context.watch<FinanceRepository>().wallets;
    final pickerWallet = wallets.isEmpty ? null : wallets[_pickerIndex % wallets.length];
    final connectedWallet = wallets.where((w) => w.id == _status.connectedWalletId).firstOrNull;
    return JagoSettingsView(
      loading: _loading,
      busy: _busy,
      status: _status,
      pickerWallet: pickerWallet,
      connectedWallet: connectedWallet,
      onCycleWallet: () => _cycleWallet(wallets.length),
      onConnect: pickerWallet == null ? null : () => _connect(pickerWallet.id),
      onDisconnect: _disconnect,
      onTapBack: () => Navigator.of(context).pop(),
    );
  }
}
