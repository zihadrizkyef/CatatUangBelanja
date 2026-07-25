import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:intl/intl.dart';

import '../models/category.dart' as models;
import '../models/icon_type.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/header_circle_button.dart';
import '../widgets/openmoji_icon.dart';
import '../widgets/transaction_history_row.dart';

final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

/// A single row of [WalletDetailView]'s transaction list, pre-joined with
/// its category (income/expense) or counterpart wallet (transfer) and a
/// display-ready relative date.
typedef WalletDetailTransactionData = ({
  Transaction transaction,
  models.Category? category,
  Wallet? counterpartWallet,
  bool isTransferIn,
  String relativeDate,
});

/// Pure wallet-detail layout: hero header (icon, name, balance, edit
/// action) and that wallet's own transaction history. All data/callbacks
/// come from the [WalletDetailScreen] container — this widget never reads
/// [FinanceRepository] or [Navigator] itself.
class WalletDetailView extends StatelessWidget {
  const WalletDetailView({
    super.key,
    required this.wallet,
    required this.balance,
    required this.transactions,
    required this.onClose,
    required this.onEdit,
    this.onSeeAll,
  });

  final Wallet wallet;
  final int balance;
  final List<WalletDetailTransactionData> transactions;
  final VoidCallback onClose;
  final VoidCallback onEdit;

  /// Opens Semua Transaksi scoped to this wallet — null (and hidden) when
  /// [transactions] is empty, matching the mockup's `hasTransactions` guard.
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final iconAsset = AppIcons.byIconValue[wallet.iconValue];

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
                padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 18, 16, 26),
                color: AppColors.accent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        HeaderCircleButton(icon: Icons.chevron_left, onTap: onClose),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Detail Dompet',
                            overflow: TextOverflow.ellipsis,
                            style: AppTheme.heading(fontSize: 18, color: Colors.white),
                          ),
                        ),
                        HeaderCircleButton(icon: Icons.edit_rounded, iconSize: 16, onTap: onEdit),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: iconAsset != null ? OpenMojiIcon(iconAsset, size: 45) : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                wallet.name,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.body(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              Row(
                                children: [
                                  Text(_currency.format(balance), style: AppTheme.heading(fontSize: 28, color: Colors.white)),
                                  if (balance < 0) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Riwayat Transaksi', style: AppTheme.heading(fontSize: 13, color: palette.textPrimary)),
                        if (onSeeAll != null)
                          TextButton(
                            onPressed: onSeeAll,
                            child: Text(
                              'Lihat Semua',
                              style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (transactions.isEmpty)
                      EmptyState(
                        palette: palette,
                        icon: AppIcons.emptyReceipt,
                        iconSize: 42,
                        bordered: false,
                        title: 'Belum ada transaksi di dompet ini, Bun.',
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: palette.cardBg,
                          border: Border.all(color: palette.border),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < transactions.length; i++)
                              TransactionHistoryRow(
                                transaction: transactions[i].transaction,
                                category: transactions[i].category,
                                wallet: transactions[i].counterpartWallet,
                                isTransferIn: transactions[i].isTransferIn,
                                relativeDate: transactions[i].relativeDate,
                                palette: palette,
                                showDivider: i < transactions.length - 1,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _previewWallet = Wallet(
  id: 'preview-wallet',
  name: 'Dompet Tunai',
  type: WalletType.cash,
  color: '#F7C6D9',
  iconType: IconType.system,
  iconValue: 'wallet_cash',
  createdAt: DateTime(2026, 1, 1),
);

@Preview(name: 'WalletDetailView')
Widget previewWalletDetailView() {
  return WalletDetailView(
    wallet: _previewWallet,
    balance: 850000,
    transactions: [
      (
        transaction: Transaction(
          id: 'preview-tx',
          type: TransactionType.expense,
          amount: 45000,
          walletId: 'preview-wallet',
          categoryId: 'preview-category',
          dateTime: DateTime(2026, 7, 6),
          createdAt: DateTime(2026, 7, 6),
          updatedAt: DateTime(2026, 7, 6),
        ),
        category: const models.Category(
          id: 'preview-category',
          name: 'Dapur',
          type: models.CategoryType.expense,
          color: '#E8637C',
          iconType: IconType.system,
          iconValue: 'category_kitchen',
        ),
        counterpartWallet: null,
        isTransferIn: false,
        relativeDate: 'Hari ini',
      ),
      (
        transaction: Transaction(
          id: 'preview-transfer',
          type: TransactionType.transfer,
          amount: 500000,
          walletId: 'preview-wallet-bank',
          targetWalletId: 'preview-wallet',
          dateTime: DateTime(2026, 7, 5),
          createdAt: DateTime(2026, 7, 5),
          updatedAt: DateTime(2026, 7, 5),
        ),
        category: null,
        counterpartWallet: Wallet(
          id: 'preview-wallet-bank',
          name: 'Rekening Bank',
          type: WalletType.bank,
          color: '#DCD3F0',
          iconType: IconType.system,
          iconValue: 'wallet_bank',
          createdAt: DateTime(2026, 1, 1),
        ),
        isTransferIn: true,
        relativeDate: 'Kemarin',
      ),
    ],
    onClose: () {},
    onEdit: () {},
    onSeeAll: () {},
  );
}

@Preview(name: 'WalletDetailView · kosong')
Widget previewWalletDetailViewEmpty() {
  return WalletDetailView(
    wallet: _previewWallet,
    balance: 0,
    transactions: const [],
    onClose: () {},
    onEdit: () {},
  );
}

@Preview(name: 'WalletDetailView · saldo minus')
Widget previewWalletDetailViewNegative() {
  return WalletDetailView(
    wallet: _previewWallet,
    balance: -111,
    transactions: const [],
    onClose: () {},
    onEdit: () {},
  );
}
