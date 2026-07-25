import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../models/icon_type.dart';
import '../models/wallet.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'openmoji_icon.dart';

/// A "Dari"/"Ke" wallet selector chip in [TransferSheetView] — tapping it
/// cycles to the next wallet, rather than opening a picker sheet.
class WalletPickerButton extends StatelessWidget {
  const WalletPickerButton({super.key, required this.label, required this.wallet, required this.palette, required this.onTap});

  final String label;
  final Wallet? wallet;
  final AppPalette palette;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconAsset = wallet == null ? null : AppIcons.byIconValue[wallet!.iconValue];

    return Material(
      color: palette.chipNeutral,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTheme.body(fontSize: 11, fontWeight: FontWeight.bold, color: palette.textSecondary)),
              const SizedBox(height: 2),
              Row(
                children: [
                  if (iconAsset != null) ...[
                    OpenMojiIcon(iconAsset, size: 30),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      wallet?.name ?? '-',
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: palette.textPrimary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@Preview(name: 'WalletPickerButton')
Widget previewWalletPickerButton() {
  return WalletPickerButton(
    label: 'Dari',
    wallet: Wallet(
      id: 'preview-wallet',
      name: 'Dompet Tunai',
      type: WalletType.cash,
      color: '#F7C6D9',
      iconType: IconType.system,
      iconValue: 'wallet_cash',
      createdAt: DateTime(2026, 1, 1),
    ),
    palette: AppPalette.light,
    onTap: () {},
  );
}
