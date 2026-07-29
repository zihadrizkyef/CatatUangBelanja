import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../repositories/finance_repository.dart';
import '../services/sync_service.dart';
import '../utils/relative_date.dart';
import 'all_transactions_screen.dart';
import 'budget_screen.dart';
import 'home_view.dart';
import 'transaction_sheet.dart';

/// Beranda tab container: reads [FinanceRepository], derives the budget
/// warning/recent-transaction data [HomeView] needs, and wires up navigation
/// callbacks (Kelola anggaran, Lihat semua, sync toast).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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

  void _openBudgetScreen() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BudgetScreen()));
  }

  void _openAllTransactions() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AllTransactionsScreen()));
  }

  void _editTransaction(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionSheet(existing: transaction),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<FinanceRepository>();
    final syncService = context.watch<SyncService>();

    final budgetStatuses = repository.budgetStatuses;
    final topWarning = budgetStatuses.where((b) => b.pct >= 80).firstOrNull;

    final recentTransactions = repository.transactions.toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return HomeView(
      greeting: _greeting(),
      isLoading: repository.isLoading,
      totalBalance: repository.totalBalance,
      budgetStatuses: budgetStatuses,
      topWarning: topWarning,
      recentTransactions: [
        for (final t in recentTransactions.take(5))
          (
            transaction: t,
            category: repository.categories.where((c) => c.id == t.categoryId).firstOrNull,
            wallet: repository.wallets.where((w) => w.id == t.walletId).firstOrNull,
            targetWallet: repository.wallets.where((w) => w.id == t.targetWalletId).firstOrNull,
            relativeDate: relativeDateLabel(t.dateTime),
            onTap: () => _editTransaction(t),
          ),
      ],
      syncState: syncService.state,
      onTapSync: syncService.syncNow,
      onOpenBudget: _openBudgetScreen,
      onSeeAllTransactions: _openAllTransactions,
    );
  }
}
