import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:intl/intl.dart';

import '../models/budget.dart';
import '../models/budget_status.dart';
import '../models/category.dart' as models;
import '../models/icon_type.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../theme/app_theme.dart';
import 'empty_transactions_card.dart';
import 'hero_banner.dart';
import 'home_transaction_row.dart';
import 'no_budget_banner.dart';
import 'safe_budget_banner.dart';
import 'warning_budget_banner.dart';

final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

/// A single row of Beranda's "Transaksi Terbaru" list, pre-joined with its
/// category/wallet and a display-ready relative date.
typedef HomeTransactionRowData = ({
  Transaction transaction,
  models.Category? category,
  Wallet? wallet,
  String relativeDate,
});

/// Pure Beranda layout: hero greeting + sync status, overlapping balance
/// card, budget status banner, and recent transactions. All data and
/// callbacks come from the [HomeScreen] container — this widget never reads
/// [FinanceRepository] or [Navigator] itself.
class HomeView extends StatelessWidget {
  const HomeView({
    super.key,
    required this.greeting,
    required this.totalBalance,
    required this.budgetStatuses,
    required this.topWarning,
    required this.recentTransactions,
    required this.onTapSync,
    required this.onOpenBudget,
    required this.onGoToSummary,
  });

  final String greeting;
  final int totalBalance;
  final List<BudgetStatus> budgetStatuses;
  final BudgetStatus? topWarning;
  final List<HomeTransactionRowData> recentTransactions;
  final VoidCallback onTapSync;
  final VoidCallback onOpenBudget;
  final VoidCallback? onGoToSummary;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.accentHeaderOverlay,
      child: Scaffold(
        backgroundColor: palette.screenBg,
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              HeroBanner(greeting: greeting, onTapSync: onTapSync),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Transform.translate(
                  offset: const Offset(0, -40),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: palette.cardBg,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: palette.cardShadow,
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total Saldo', style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: palette.textSecondary)),
                        const SizedBox(height: 2),
                        Text(_currency.format(totalBalance), style: AppTheme.heading(fontSize: 30, color: palette.textPrimary)),
                      ],
                    ),
                  ),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -20),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Anggaran', style: AppTheme.heading(fontSize: 14, color: palette.textPrimary)),
                          TextButton(
                            onPressed: onOpenBudget,
                            child: Text('Kelola →', style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: palette.textSecondary)),
                          ),
                        ],
                      ),
                      if (topWarning != null)
                        WarningBudgetBanner(status: topWarning!, palette: palette)
                      else if (budgetStatuses.isNotEmpty)
                        SafeBudgetBanner(palette: palette)
                      else
                        NoBudgetBanner(palette: palette, onTap: onOpenBudget),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Transaksi Terbaru', style: AppTheme.heading(fontSize: 14, color: palette.textPrimary)),
                          TextButton(
                            onPressed: onGoToSummary,
                            child: Text('Lihat semua →', style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: palette.textSecondary)),
                          ),
                        ],
                      ),
                      if (recentTransactions.isEmpty)
                        EmptyTransactionsCard(palette: palette)
                      else
                        Column(
                          children: [
                            for (final row in recentTransactions)
                              HomeTransactionRow(
                                transaction: row.transaction,
                                category: row.category,
                                wallet: row.wallet,
                                relativeDate: row.relativeDate,
                                palette: palette,
                              ),
                          ],
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _previewCategory = models.Category(
  id: 'preview-category',
  name: 'Dapur',
  type: models.CategoryType.expense,
  color: '#E8637C',
  iconType: IconType.system,
  iconValue: 'category_kitchen',
);

final _previewWallet = Wallet(
  id: 'preview-wallet',
  name: 'Dompet Tunai',
  type: WalletType.cash,
  color: '#E8637C',
  iconType: IconType.system,
  iconValue: 'wallet_cash',
  createdAt: DateTime(2026, 1, 1),
);

@Preview(name: 'HomeView · dengan peringatan anggaran')
Widget previewHomeViewWithWarning() {
  return HomeView(
    greeting: 'Selamat pagi, Bun 👋',
    totalBalance: 2450000,
    budgetStatuses: [
      BudgetStatus(
        category: _previewCategory,
        budget: Budget(id: 'preview-budget', categoryId: 'preview-category', limitAmount: 1000000, createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1)),
        used: 850000,
        pct: 85,
      ),
    ],
    topWarning: BudgetStatus(
      category: _previewCategory,
      budget: Budget(id: 'preview-budget', categoryId: 'preview-category', limitAmount: 1000000, createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1)),
      used: 850000,
      pct: 85,
    ),
    recentTransactions: [
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
        category: _previewCategory,
        wallet: _previewWallet,
        relativeDate: 'Hari ini',
      ),
    ],
    onTapSync: () {},
    onOpenBudget: () {},
    onGoToSummary: () {},
  );
}

@Preview(name: 'HomeView · kosong')
Widget previewHomeViewEmpty() {
  return HomeView(
    greeting: 'Selamat siang, Bun 👋',
    totalBalance: 0,
    budgetStatuses: const [],
    topWarning: null,
    recentTransactions: const [],
    onTapSync: () {},
    onOpenBudget: () {},
    onGoToSummary: () {},
  );
}
