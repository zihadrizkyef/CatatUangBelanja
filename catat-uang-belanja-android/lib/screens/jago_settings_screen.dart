import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/jago_service.dart';
import '../theme/app_theme.dart';
import '../utils/snackbar.dart';
import 'jago_settings_view.dart';

/// Pengaturan > Bank Jago screen: connects the Bank Jago email sync
/// (integrasi-jago) via [JagoService], or shows/disconnects an existing
/// connection. No wallet to pick — sync auto-creates and manages one
/// wallet per Kantong (pocket) as they're discovered in Zihad's Gmail.
/// Reads [JagoService] for the connect/disconnect/status calls; hands the
/// rest to [JagoSettingsView].
class JagoSettingsScreen extends StatefulWidget {
  const JagoSettingsScreen({super.key});

  @override
  State<JagoSettingsScreen> createState() => _JagoSettingsScreenState();
}

class _JagoSettingsScreenState extends State<JagoSettingsScreen> {
  bool _loading = true;
  bool _busy = false;
  JagoStatus _status = JagoStatus.disconnected;

  @override
  void initState() {
    super.initState();
    _loadStatus();
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

  Future<void> _connect() async {
    setState(() => _busy = true);
    try {
      // The backend kicks off the (possibly long, for a first connect with
      // years of history) sync in the background rather than waiting for
      // it — so there's no import count to report here yet, just that the
      // connection itself succeeded.
      await context.read<JagoService>().connect();
      if (!mounted) return;
      showSnackBarMessage(
        context,
        'Bank Jago terhubung! Transaksinya lagi disinkronkan di belakang — cek lagi sebentar ya, Bun ✨',
      );
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
    return JagoSettingsView(
      loading: _loading,
      busy: _busy,
      status: _status,
      onConnect: _connect,
      onDisconnect: _disconnect,
      onTapBack: () => Navigator.of(context).pop(),
    );
  }
}
