import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repositories/finance_repository.dart';
import 'wallet_view.dart';

/// Dompet tab container: reads [FinanceRepository] for the wallet list,
/// combined balance, and transaction history, and wires up the "+ Tambah
/// Dompet" stub toast; hands the rest to [WalletView].
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  String _relativeDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diff = today.difference(day).inDays;
    if (diff <= 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    return '$diff hari lalu';
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Segera hadir ✨'), duration: Duration(milliseconds: 1200)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<FinanceRepository>();
    final wallets = repository.wallets.where((w) => !w.isArchived).toList();

    final transactions = repository.transactions.toList()..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return WalletView(
      totalBalance: repository.totalBalance,
      wallets: wallets,
      walletBalances: [for (final w in wallets) repository.balanceOf(w.id)],
      transactions: [
        for (final t in transactions)
          (
            transaction: t,
            category: repository.categories.where((c) => c.id == t.categoryId).firstOrNull,
            wallet: repository.wallets.where((w) => w.id == t.walletId).firstOrNull,
            relativeDate: _relativeDate(t.dateTime),
          ),
      ],
      onTapAddWallet: _showComingSoon,
    );
  }
}
