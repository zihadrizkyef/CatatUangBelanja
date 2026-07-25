import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:intl/intl.dart';

import '../models/icon_type.dart';
import '../models/wallet.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/sheet_padding.dart';
import '../widgets/numeric_keypad.dart';
import '../widgets/wallet_picker_button.dart';

/// Pure layout for [TransferSheet]: the amount keypad and "Dari"/"Ke" wallet
/// pickers. All data/callbacks come from the [TransferSheet] container —
/// this widget never touches [FinanceRepository] or [Navigator] itself.
class TransferSheetView extends StatelessWidget {
  const TransferSheetView({
    super.key,
    required this.fromWallet,
    required this.toWallet,
    required this.amountStr,
    required this.onCycleFrom,
    required this.onCycleTo,
    required this.onKeyTap,
    required this.onClose,
  });

  final Wallet? fromWallet;
  final Wallet? toWallet;
  final String amountStr;

  /// Null when there are fewer than two wallets to choose between.
  final VoidCallback? onCycleFrom;
  final VoidCallback? onCycleTo;
  final ValueChanged<String> onKeyTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(18, 18, 18, sheetBottomPadding(context)),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Transfer Saldo', style: AppTheme.heading(fontSize: 17, color: palette.textPrimary)),
                Material(
                  color: palette.warningBg,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onClose,
                    child: SizedBox(
                      width: 38,
                      height: 38,
                      child: Icon(Icons.close, size: 20, color: palette.textPrimary),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Rp ${amountStr.isEmpty ? '0' : NumberFormat('#,###', 'id_ID').format(int.parse(amountStr))}',
              textAlign: TextAlign.center,
              style: AppTheme.heading(fontSize: 30, color: palette.textPrimary),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: WalletPickerButton(label: 'Dari', wallet: fromWallet, palette: palette, onTap: onCycleFrom)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('→', style: AppTheme.body(fontSize: 18, color: palette.textSecondary)),
                ),
                Expanded(child: WalletPickerButton(label: 'Ke', wallet: toWallet, palette: palette, onTap: onCycleTo)),
              ],
            ),
            const SizedBox(height: 16),
            NumericKeypad(confirmColor: AppColors.okBar, palette: palette, onKeyTap: onKeyTap),
          ],
        ),
      ),
    );
  }
}

final _previewFromWallet = Wallet(
  id: 'preview-wallet-1',
  name: 'Dompet Tunai',
  type: WalletType.cash,
  color: '#F7C6D9',
  iconType: IconType.system,
  iconValue: 'wallet_cash',
  createdAt: DateTime(2026, 1, 1),
);

final _previewToWallet = Wallet(
  id: 'preview-wallet-2',
  name: 'Rekening Bank',
  type: WalletType.bank,
  color: '#DCD3F0',
  iconType: IconType.system,
  iconValue: 'wallet_bank',
  createdAt: DateTime(2026, 1, 1),
);

@Preview(name: 'TransferSheetView')
Widget previewTransferSheetView() {
  return TransferSheetView(
    fromWallet: _previewFromWallet,
    toWallet: _previewToWallet,
    amountStr: '250000',
    onCycleFrom: () {},
    onCycleTo: () {},
    onKeyTap: (_) {},
    onClose: () {},
  );
}
