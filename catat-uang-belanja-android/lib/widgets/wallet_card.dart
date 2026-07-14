import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:intl/intl.dart';

import '../models/icon_type.dart';
import '../models/wallet.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'openmoji_icon.dart';

final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

/// Fixed pastel circle behind every wallet icon, per the mockup (hardcoded
/// `#FCE0E1` regardless of light/dark theme).
const _walletIconBg = Color(0xFFFCE0E1);

/// A single wallet row in Dompet's "Dompet Saya" list. Tapping it opens the
/// edit sheet.
class WalletCard extends StatelessWidget {
  const WalletCard({
    super.key,
    required this.wallet,
    required this.indexLabel,
    required this.balance,
    required this.palette,
    required this.onTap,
  });

  final Wallet wallet;
  final String indexLabel;
  final int balance;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconAsset = AppIcons.byIconValue[wallet.iconValue];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: palette.cardBg,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(color: _walletIconBg, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: iconAsset != null
                      ? OpenMojiIcon(iconAsset, size: 27)
                      : Icon(Icons.account_balance_wallet_rounded, size: 24, color: palette.textPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(wallet.name, style: AppTheme.body(fontSize: 14, fontWeight: FontWeight.bold, color: palette.textPrimary)),
                      Text(
                        'Rekening $indexLabel',
                        style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: palette.textSecondary),
                      ),
                    ],
                  ),
                ),
                Text(_currency.format(balance), style: AppTheme.heading(fontSize: 15, color: palette.textPrimary)),
                const SizedBox(width: 6),
                Text('›', style: TextStyle(fontSize: 14, color: palette.borderStrong)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

@Preview(name: 'WalletCard')
Widget previewWalletCard() {
  return WalletCard(
    wallet: Wallet(
      id: 'preview-wallet',
      name: 'Dompet Tunai',
      type: WalletType.cash,
      color: '#E8637C',
      iconType: IconType.system,
      iconValue: 'wallet_cash',
      createdAt: DateTime(2026, 1, 1),
    ),
    indexLabel: '1/2',
    balance: 1250000,
    palette: AppPalette.light,
    onTap: () {},
  );
}
