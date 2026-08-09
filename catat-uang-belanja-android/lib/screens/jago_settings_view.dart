import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:intl/intl.dart';

import '../models/icon_type.dart';
import '../models/wallet.dart';
import '../services/jago_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/wallet_picker_button.dart';

final _connectedSince = DateFormat('d MMM yyyy', 'id_ID');

/// Pure Bank Jago settings layout: connect flow ("Hubungkan Gmail", with a
/// wallet picker for the nameless "Kantong Terhubung") or connected state
/// ("Putuskan"). Named Kantong (Tabungan, Modal Bisnis, dst.) auto-match by
/// name and need no picker. All data/callbacks come from
/// [JagoSettingsScreen] — this widget never reads a repository/service or
/// [Navigator] itself.
class JagoSettingsView extends StatelessWidget {
  const JagoSettingsView({
    super.key,
    required this.loading,
    required this.busy,
    required this.status,
    required this.pickerWallet,
    required this.connectedWallet,
    required this.onCycleWallet,
    required this.onConnect,
    required this.onDisconnect,
    required this.onTapBack,
  });

  final bool loading;
  final bool busy;
  final JagoStatus status;
  final Wallet? pickerWallet;
  final Wallet? connectedWallet;
  final VoidCallback onCycleWallet;
  final VoidCallback? onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onTapBack;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.accentHeaderOverlay,
      child: Scaffold(
        backgroundColor: palette.screenBg,
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 18, 16, 20),
                color: AppColors.accent,
                child: Row(
                  children: [
                    Material(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onTapBack,
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(Icons.chevron_left, color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Bank Jago 🏦', style: AppTheme.heading(fontSize: 18, color: Colors.white)),
                  ],
                ),
              ),
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                        children: [
                          if (status.connected) ..._connectedContent(palette) else ..._connectContent(palette),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _connectContent(AppPalette palette) {
    return [
      Text(
        'Hubungkan Gmail yang menerima notifikasi transaksi Bank Jago kamu — transaksi barunya langsung tercatat mulai dari sekarang, Bun. Kantong Tabungan/Modal Bisnis dan sejenisnya otomatis nyambung sendiri kalau nama dompetnya sama.',
        style: AppTheme.body(fontSize: 13, color: palette.textSecondary),
      ),
      const SizedBox(height: 14),
      Text(
        'Pilih dompet kamu yang menangani transaksi kartu, QRIS, transfer, top up, dan tarik tunai di Bank Jago — biasanya dompet utama kamu (bukan dompet tabungan/Kantong khusus).',
        style: AppTheme.body(fontSize: 13, color: palette.textSecondary),
      ),
      const SizedBox(height: 10),
      WalletPickerButton(
        label: 'Kantong Terhubung',
        wallet: pickerWallet,
        palette: palette,
        onTap: pickerWallet == null ? null : onCycleWallet,
      ),
      const SizedBox(height: 18),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: busy ? null : onConnect,
          child: busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Hubungkan Gmail'),
        ),
      ),
    ];
  }

  List<Widget> _connectedContent(AppPalette palette) {
    return [
      Material(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: palette.border), borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bank Jago terhubung',
                style: AppTheme.body(fontSize: 14, fontWeight: FontWeight.bold, color: palette.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                status.connectedAt == null ? 'Terhubung' : 'Terhubung sejak ${_connectedSince.format(status.connectedAt!)}',
                style: AppTheme.body(fontSize: 12, color: palette.textSecondary),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        connectedWallet == null
            ? 'Kantong Terhubung tersambung ke sebuah dompet.'
            : 'Kantong Terhubung tersambung ke dompet "${connectedWallet!.name}".',
        style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: palette.textPrimary),
      ),
      const SizedBox(height: 4),
      Text(
        'Kantong Tabungan/Modal Bisnis dan sejenisnya otomatis nyambung sendiri ke dompet dengan nama yang sama, dan tiap transaksi baru tercatat setiap sinkron, Bun.',
        style: AppTheme.body(fontSize: 13, color: palette.textSecondary),
      ),
      const SizedBox(height: 18),
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: busy ? null : onDisconnect,
          child: busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Putuskan'),
        ),
      ),
    ];
  }
}

final _previewWallet = Wallet(
  id: 'preview-wallet',
  name: 'Dompet Utama',
  type: WalletType.bank,
  color: '#DCD3F0',
  iconType: IconType.system,
  iconValue: 'wallet_bank',
  createdAt: DateTime(2026, 1, 1),
);

@Preview(name: 'JagoSettingsView · belum terhubung')
Widget previewJagoSettingsViewDisconnected() {
  return JagoSettingsView(
    loading: false,
    busy: false,
    status: JagoStatus.disconnected,
    pickerWallet: _previewWallet,
    connectedWallet: null,
    onCycleWallet: () {},
    onConnect: () {},
    onDisconnect: () {},
    onTapBack: () {},
  );
}

@Preview(name: 'JagoSettingsView · terhubung')
Widget previewJagoSettingsViewConnected() {
  return JagoSettingsView(
    loading: false,
    busy: false,
    status: JagoStatus(connected: true, connectedAt: DateTime(2026, 8, 1), connectedWalletId: _previewWallet.id),
    pickerWallet: _previewWallet,
    connectedWallet: _previewWallet,
    onCycleWallet: () {},
    onConnect: null,
    onDisconnect: () {},
    onTapBack: () {},
  );
}
