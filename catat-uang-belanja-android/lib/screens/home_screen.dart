import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/budget_status.dart';
import '../models/category.dart' as models;
import '../models/transaction.dart';
import '../models/wallet.dart' show Wallet;
import '../repositories/finance_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'budget_screen.dart';

final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

/// Beranda tab: hero greeting + sync status, overlapping balance card,
/// budget status banner (warning/all-safe/no-budgets-yet), and recent
/// transactions — all computed live from [FinanceRepository].
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onGoToSummary});

  /// Switches the parent [AppShell] to the Rangkuman tab ("Lihat semua →").
  final VoidCallback? onGoToSummary;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat pagi, Bun 👋';
    if (hour < 15) return 'Selamat siang, Bun 👋';
    if (hour < 18) return 'Selamat sore, Bun 👋';
    return 'Selamat malam, Bun 👋';
  }

  String _relativeDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    return '$diff hari lalu';
  }

  void _openBudgetScreen(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BudgetScreen()));
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Segera hadir ✨'), duration: Duration(milliseconds: 1200)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<FinanceRepository>();
    final palette = AppPalette.of(context);

    final budgetStatuses = repository.budgetStatuses;
    final topWarning = budgetStatuses.where((b) => b.pct >= 80).firstOrNull;

    final recentTransactions = repository.transactions.toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return Scaffold(
      backgroundColor: palette.screenBg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            _Hero(greeting: _greeting(), onTapSync: () => _showComingSoon(context)),
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
                        color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.35 : 0.12),
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
                      Text(_currency.format(repository.totalBalance), style: AppTheme.heading(fontSize: 30, color: palette.textPrimary)),
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
                          onPressed: () => _openBudgetScreen(context),
                          child: Text('Kelola →', style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: palette.textSecondary)),
                        ),
                      ],
                    ),
                    if (topWarning != null)
                      _WarningBudgetBanner(status: topWarning, palette: palette)
                    else if (budgetStatuses.isNotEmpty)
                      _SafeBudgetBanner(palette: palette)
                    else
                      _NoBudgetBanner(palette: palette, onTap: () => _openBudgetScreen(context)),
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
                      _EmptyTransactions(palette: palette)
                    else
                      Column(
                        children: [
                          for (final t in recentTransactions.take(5))
                            _TransactionRow(
                              transaction: t,
                              category: repository.categories.where((c) => c.id == t.categoryId).firstOrNull,
                              wallet: repository.wallets.where((w) => w.id == t.walletId).firstOrNull,
                              relativeDate: _relativeDate(t.dateTime),
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
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.greeting, required this.onTapSync});

  final String greeting;
  final VoidCallback onTapSync;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 56),
      color: AppColors.accent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting, style: AppTheme.heading(fontSize: 21, color: Colors.white)),
                const SizedBox(height: 2),
                Text('Yuk catat belanja hari ini', style: AppTheme.body(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.9))),
              ],
            ),
          ),
          Material(
            color: Colors.white.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onTapSync,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const TwemojiIcon(AppIcons.syncOffline, size: 14),
                    const SizedBox(width: 5),
                    Text('Offline', style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningBudgetBanner extends StatelessWidget {
  const _WarningBudgetBanner({required this.status, required this.palette});

  final BudgetStatus status;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final clampedPct = status.pct.clamp(0, 100);
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: palette.warningBg, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: palette.cardBg, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: TwemojiIcon(AppIcons.byIconValue[status.category.iconValue] ?? AppIcons.budgetTarget, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(status.category.name, style: AppTheme.body(fontSize: 14, fontWeight: FontWeight.bold, color: palette.textPrimary)),
                    Text(
                      '${_currency.format(status.used)} dari ${_currency.format(status.budget.limitAmount)}',
                      style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: palette.textSecondary),
                    ),
                  ],
                ),
              ),
              Text('${status.pct}%', style: AppTheme.heading(fontSize: 15, color: palette.warningText)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: clampedPct / 100,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _SafeBudgetBanner extends StatelessWidget {
  const _SafeBudgetBanner({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: palette.safeBg, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          const TwemojiIcon(AppIcons.budgetSafe, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Semua anggaran masih aman, Bun. Mantap!',
              style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: palette.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoBudgetBanner extends StatelessWidget {
  const _NoBudgetBanner({required this.palette, required this.onTap});

  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.chipNeutral,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(top: 8, bottom: 8),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const TwemojiIcon(AppIcons.budgetTarget, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Belum ada anggaran. Yuk buat yang pertama.',
                  style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: palette.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 34),
      child: Column(
        children: [
          const TwemojiIcon(AppIcons.emptyReceipt, size: 32),
          const SizedBox(height: 8),
          Text(
            'Belum ada transaksi, Bun. Yuk catat yang pertama.',
            textAlign: TextAlign.center,
            style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.transaction,
    required this.category,
    required this.wallet,
    required this.relativeDate,
    required this.palette,
  });

  final Transaction transaction;
  final models.Category? category;
  final Wallet? wallet;
  final String relativeDate;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final label = category?.name ?? (isIncome ? 'Pemasukan' : 'Pengeluaran');
    final sub = (transaction.note?.isNotEmpty ?? false) ? transaction.note! : (wallet?.name ?? '');
    final iconBg = category != null ? Color(int.parse(category!.color.replaceFirst('#', '0xFF'))) : AppColors.lightChipNeutral;
    final iconAsset = category != null ? AppIcons.byIconValue[category!.iconValue] : null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: palette.cardBg, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: iconAsset != null
                ? TwemojiIcon(iconAsset, size: 18)
                : Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, size: 16, color: palette.textPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTheme.body(fontSize: 14, fontWeight: FontWeight.bold, color: palette.textPrimary)),
                Text('$sub · $relativeDate', style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: palette.textSecondary)),
              ],
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'}${_currency.format(transaction.amount)}',
            style: AppTheme.body(fontSize: 14, fontWeight: FontWeight.bold, color: isIncome ? AppColors.gold : AppColors.peach),
          ),
        ],
      ),
    );
  }
}
