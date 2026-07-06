import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/category.dart' as models;
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../repositories/finance_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../theme/dashed_line.dart';

final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

/// Fixed pastel circle behind every wallet icon, per the mockup (hardcoded
/// `#FCE0E1` regardless of light/dark theme).
const _walletIconBg = Color(0xFFFCE0E1);

/// Dompet tab: hero header with the combined balance across all wallets,
/// the wallet list, and transaction history — all live from
/// [FinanceRepository].
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  String _relativeDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    return '$diff hari lalu';
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
    final wallets = repository.wallets.where((w) => !w.isArchived).toList();

    final transactions = repository.transactions.toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return Scaffold(
      backgroundColor: palette.screenBg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 26),
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
                  Text(
                    _currency.format(repository.totalBalance),
                    style: AppTheme.heading(fontSize: 34, color: Colors.white),
                  ),
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
                  for (var i = 0; i < wallets.length; i++)
                    _WalletCard(
                      wallet: wallets[i],
                      indexLabel: '${i + 1}/${wallets.length}',
                      balance: repository.balanceOf(wallets[i].id),
                      palette: palette,
                    ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: Material(
                      color: palette.warningBg,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _showComingSoon(context),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 34),
                      child: Column(
                        children: [
                          const TwemojiIcon(AppIcons.emptyReceipt, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            'Belum ada transaksi di dompet ini, Bun.',
                            textAlign: TextAlign.center,
                            style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: palette.textSecondary),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final t in transactions)
                      _TransactionHistoryRow(
                        transaction: t,
                        category: repository.categories.where((c) => c.id == t.categoryId).firstOrNull,
                        wallet: repository.wallets.where((w) => w.id == t.walletId).firstOrNull,
                        relativeDate: _relativeDate(t.dateTime),
                        palette: palette,
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.wallet, required this.indexLabel, required this.balance, required this.palette});

  final Wallet wallet;
  final String indexLabel;
  final int balance;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final iconAsset = AppIcons.byIconValue[wallet.iconValue];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.cardBg,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(color: _walletIconBg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: iconAsset != null
                ? TwemojiIcon(iconAsset, size: 19)
                : Icon(Icons.account_balance_wallet_rounded, size: 18, color: palette.textPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(wallet.name, style: AppTheme.body(fontSize: 14, fontWeight: FontWeight.bold, color: palette.textPrimary)),
                Text('Rekening $indexLabel', style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: palette.textSecondary)),
              ],
            ),
          ),
          Text(
            _currency.format(balance),
            style: AppTheme.heading(fontSize: 15, color: palette.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _TransactionHistoryRow extends StatelessWidget {
  const _TransactionHistoryRow({
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
    final iconAsset = category != null ? AppIcons.byIconValue[category!.iconValue] : null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            children: [
              iconAsset != null
                  ? TwemojiIcon(iconAsset, size: 16)
                  : Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, size: 14, color: palette.textPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: palette.textPrimary)),
                    Text('$sub · $relativeDate', style: AppTheme.body(fontSize: 11, fontWeight: FontWeight.bold, color: palette.textSecondary)),
                  ],
                ),
              ),
              Text(
                '${isIncome ? '+' : '-'}${_currency.format(transaction.amount)}',
                style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: isIncome ? AppColors.gold : AppColors.peach),
              ),
            ],
          ),
        ),
        DashedLine(color: palette.borderStrong),
      ],
    );
  }
}
