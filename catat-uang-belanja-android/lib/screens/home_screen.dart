import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repositories/finance_repository.dart';
import 'budget_screen.dart';
import 'home_view.dart';

/// Beranda tab container: reads [FinanceRepository], derives the budget
/// warning/recent-transaction data [HomeView] needs, and wires up navigation
/// callbacks (Kelola anggaran, Lihat semua, sync toast).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onGoToSummary});

  /// Switches the parent [AppShell] to the Rangkuman tab ("Lihat semua →").
  final VoidCallback? onGoToSummary;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  void _openBudgetScreen() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BudgetScreen()));
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Segera hadir ✨'),
        duration: Duration(milliseconds: 1200),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<FinanceRepository>();

    final budgetStatuses = repository.budgetStatuses;
    final topWarning = budgetStatuses.where((b) => b.pct >= 80).firstOrNull;

    final recentTransactions = repository.transactions.toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return HomeView(
      greeting: _greeting(),
      totalBalance: repository.totalBalance,
      budgetStatuses: budgetStatuses,
      topWarning: topWarning,
      recentTransactions: [
        for (final t in recentTransactions.take(5))
          (
            transaction: t,
            category: repository.categories.where((c) => c.id == t.categoryId).firstOrNull,
            wallet: repository.wallets.where((w) => w.id == t.walletId).firstOrNull,
            relativeDate: _relativeDate(t.dateTime),
          ),
      ],
      onTapSync: _showComingSoon,
      onOpenBudget: _openBudgetScreen,
      onGoToSummary: widget.onGoToSummary,
    );
  }
}
