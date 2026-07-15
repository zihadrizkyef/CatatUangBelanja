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
import '../widgets/dashed_line.dart';
import '../widgets/empty_state.dart';
import '../widgets/transaction_history_row.dart';
import '../widgets/wallet_card.dart';

final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

/// A single row of Dompet's "Riwayat Transaksi" list, pre-joined with its
/// category/wallet and a display-ready relative date.
typedef TransactionHistoryRowData = ({Transaction transaction, models.Category? category, Wallet? wallet, String relativeDate});

/// Pure Dompet layout: hero header with the combined balance across all
/// wallets, the wallet list, and transaction history. All data and
/// callbacks come from the [WalletScreen] container — this widget never
/// reads [FinanceRepository] or [ScaffoldMessenger] itself.
class WalletView extends StatelessWidget {
  const WalletView({
    super.key,
    required this.totalBalance,
    required this.wallets,
    required this.walletBalances,
    required this.transactions,
    required this.onTapAddWallet,
    required this.onTapWallet,
  });

  final int totalBalance;
  final List<Wallet> wallets;
  final List<int> walletBalances;
  final List<TransactionHistoryRowData> transactions;
  final VoidCallback onTapAddWallet;
  final ValueChanged<Wallet> onTapWallet;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.accentHeaderOverlay,
      child: Scaffold(
        backgroundColor: palette.screenBg,
        body: SafeArea(
          top: false,
          bottom: false,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 22, 20, 26),
                color: AppColors.accent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dompet 👛', style: AppTheme.heading(fontSize: 21, color: Colors.white)),
                    const SizedBox(height: 16),
                    DashedLine(color: Colors.white.withValues(alpha: 0.4)),
                    const SizedBox(height: 14),
                    Text(
                      'Total di Semua Dompet',
                      style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.85)),
                    ),
                    Text(_currency.format(totalBalance), style: AppTheme.heading(fontSize: 34, color: Colors.white)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dompet Saya', style: AppTheme.heading(fontSize: 13, color: palette.textPrimary)),
                    const SizedBox(height: 10),
                    if (wallets.isEmpty)
                      EmptyState(
                        palette: palette,
                        icon: AppIcons.wallet,
                        iconSize: 42,
                        title: 'Belum ada dompet, Bun. Yuk tambah yang pertama.',
                      )
                    else
                      for (var i = 0; i < wallets.length; i++)
                        WalletCard(
                          wallet: wallets[i],
                          balance: walletBalances[i],
                          palette: palette,
                          onTap: () => onTapWallet(wallets[i]),
                        ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: Material(
                        color: palette.warningBg,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: onTapAddWallet,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            child: Text(
                              '+ Tambah Dompet',
                              textAlign: TextAlign.center,
                              style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: palette.warningText),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Riwayat Transaksi', style: AppTheme.heading(fontSize: 13, color: palette.textPrimary)),
                    const SizedBox(height: 6),
                    if (transactions.isEmpty)
                      EmptyState(
                        palette: palette,
                        icon: AppIcons.emptyReceipt,
                        iconSize: 45,
                        bordered: false,
                        title: 'Belum ada transaksi di dompet ini, Bun.',
                      )
                    else
                      for (final row in transactions)
                        TransactionHistoryRow(
                          transaction: row.transaction,
                          category: row.category,
                          wallet: row.wallet,
                          relativeDate: row.relativeDate,
                          palette: palette,
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
  color: '#E8637C',
  iconType: IconType.system,
  iconValue: 'wallet_cash',
  createdAt: DateTime(2026, 1, 1),
);

@Preview(name: 'WalletView')
Widget previewWalletView() {
  return WalletView(
    totalBalance: 2450000,
    wallets: [_previewWallet],
    walletBalances: const [2450000],
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
        wallet: _previewWallet,
        relativeDate: 'Hari ini',
      ),
    ],
    onTapAddWallet: () {},
    onTapWallet: (_) {},
  );
}

@Preview(name: 'WalletView · kosong')
Widget previewWalletViewEmpty() {
  return WalletView(
    totalBalance: 0,
    wallets: const [],
    walletBalances: const [],
    transactions: const [],
    onTapAddWallet: () {},
    onTapWallet: (_) {},
  );
}
