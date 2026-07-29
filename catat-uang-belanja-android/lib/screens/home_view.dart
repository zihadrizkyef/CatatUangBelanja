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
import '../services/sync_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/hero_banner.dart';
import '../widgets/home_transaction_row.dart';
import '../widgets/openmoji_icon.dart';
import '../widgets/safe_budget_banner.dart';
import '../widgets/warning_budget_banner.dart';

final _currency = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
);

/// A single row of Beranda's "Transaksi Terbaru" list, pre-joined with its
/// category/wallet and a display-ready relative date.
typedef HomeTransactionRowData = ({
  Transaction transaction,
  models.Category? category,
  Wallet? wallet,
  Wallet? targetWallet,
  String relativeDate,
  VoidCallback onTap,
});

/// Pure Beranda layout: hero greeting + sync status, overlapping balance
/// card, budget status banner, and recent transactions. All data and
/// callbacks come from the [HomeScreen] container — this widget never reads
/// [FinanceRepository] or [Navigator] itself.
class HomeView extends StatelessWidget {
  const HomeView({
    super.key,
    required this.greeting,
    required this.isLoading,
    required this.totalBalance,
    required this.budgetStatuses,
    required this.topWarning,
    required this.recentTransactions,
    required this.syncState,
    required this.onTapSync,
    required this.onOpenBudget,
    required this.onSeeAllTransactions,
  });

  final String greeting;
  final SyncState syncState;

  /// True while [FinanceRepository]'s initial load is still in flight — see
  /// UX-001. Shows a neutral spinner instead of the empty-state copy, which
  /// otherwise flashes even when the database already has real data.
  final bool isLoading;
  final int totalBalance;
  final List<BudgetStatus> budgetStatuses;
  final BudgetStatus? topWarning;
  final List<HomeTransactionRowData> recentTransactions;
  final VoidCallback onTapSync;
  final VoidCallback onOpenBudget;
  final VoidCallback onSeeAllTransactions;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.accentHeaderOverlay,
      child: Scaffold(
        backgroundColor: palette.screenBg,
        body: SafeArea(
          bottom: false,
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                )
              : ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    HeroBanner(greeting: greeting, syncState: syncState, onTapSync: onTapSync),
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
                              Text(
                                'Total Saldo',
                                style: AppTheme.body(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: palette.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _currency.format(totalBalance),
                                style: AppTheme.heading(
                                  fontSize: 30,
                                  color: palette.textPrimary,
                                ),
                              ),
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
                                Semantics(
                                  header: true,
                                  container: true,
                                  child: Text(
                                    'Anggaran',
                                    style: AppTheme.heading(
                                      fontSize: 14,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: onOpenBudget,
                                  child: Text(
                                    'Kelola →',
                                    style: AppTheme.body(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: palette.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (topWarning != null)
                              WarningBudgetBanner(
                                status: topWarning!,
                                palette: palette,
                              )
                            else if (budgetStatuses.isNotEmpty)
                              SafeBudgetBanner(palette: palette)
                            else
                              Material(
                                color: palette.chipNeutral,
                                borderRadius: BorderRadius.circular(18),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(18),
                                  onTap: onOpenBudget,
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        const OpenMojiIcon(
                                          AppIcons.budgetTarget,
                                          size: 31,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Belum ada anggaran, Bun. Yuk mulai atur biar pengeluaran lebih terkontrol!',
                                            style: AppTheme.body(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: palette.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Semantics(
                                  header: true,
                                  container: true,
                                  child: Text(
                                    'Transaksi Terbaru',
                                    style: AppTheme.heading(
                                      fontSize: 14,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: onSeeAllTransactions,
                                  child: Text(
                                    'Lihat semua →',
                                    style: AppTheme.body(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: palette.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (recentTransactions.isEmpty)
                              EmptyState(
                                palette: palette,
                                icon: AppIcons.emptyReceipt,
                                iconSize: 45,
                                bordered: false,
                                title:
                                    'Belum ada transaksi, Bun. Yuk catat yang pertama.',
                              )
                            else
                              Column(
                                children: [
                                  for (final row in recentTransactions)
                                    HomeTransactionRow(
                                      transaction: row.transaction,
                                      category: row.category,
                                      wallet: row.wallet,
                                      targetWallet: row.targetWallet,
                                      relativeDate: row.relativeDate,
                                      palette: palette,
                                      onTap: row.onTap,
                                    ),
                                ],
                              ),
                            // Clears the shell's floating "+" FAB (56dp + margin),
                            // which otherwise overlaps the last transaction row
                            // since Scaffold doesn't reserve body space for it.
                            const SizedBox(height: 88),
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
    isLoading: false,
    totalBalance: 2450000,
    budgetStatuses: [
      BudgetStatus(
        category: _previewCategory,
        budget: Budget(
          id: 'preview-budget',
          categoryId: 'preview-category',
          limitAmount: 1000000,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        used: 850000,
        pct: 85,
      ),
    ],
    topWarning: BudgetStatus(
      category: _previewCategory,
      budget: Budget(
        id: 'preview-budget',
        categoryId: 'preview-category',
        limitAmount: 1000000,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
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
        targetWallet: null,
        relativeDate: 'Hari ini',
        onTap: () {},
      ),
    ],
    syncState: SyncState.idle,
    onTapSync: () {},
    onOpenBudget: () {},
    onSeeAllTransactions: () {},
  );
}

@Preview(name: 'HomeView · kosong')
Widget previewHomeViewEmpty() {
  return HomeView(
    greeting: 'Selamat siang, Bun 👋',
    isLoading: false,
    totalBalance: 0,
    budgetStatuses: const [],
    topWarning: null,
    recentTransactions: const [],
    syncState: SyncState.idle,
    onTapSync: () {},
    onOpenBudget: () {},
    onSeeAllTransactions: () {},
  );
}

@Preview(name: 'HomeView · loading')
Widget previewHomeViewLoading() {
  return HomeView(
    greeting: 'Selamat siang, Bun 👋',
    isLoading: true,
    totalBalance: 0,
    budgetStatuses: const [],
    topWarning: null,
    recentTransactions: const [],
    syncState: SyncState.idle,
    onTapSync: () {},
    onOpenBudget: () {},
    onSeeAllTransactions: () {},
  );
}
