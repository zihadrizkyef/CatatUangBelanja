import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../repositories/finance_repository.dart';
import '../theme/app_theme.dart';

final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

class BerandaScreen extends StatelessWidget {
  const BerandaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<FinanceRepository>();
    final now = DateTime.now();

    final thisMonth = repository.transactions.where(
      (t) => t.dateTime.year == now.year && t.dateTime.month == now.month,
    );
    final income = thisMonth
        .where((t) => t.type == TransactionType.income)
        .fold(0, (sum, t) => sum + t.amount);
    final expense = thisMonth
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (sum, t) => sum + t.amount);

    final recentTransactions = repository.transactions.toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Selamat datang, Bun!', style: AppTheme.heading()),
          Text('Yuk catat belanja hari ini.', style: AppTheme.body()),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Saldo', style: AppTheme.body(fontSize: 14)),
                  Text(_currency.format(repository.totalBalance), style: AppTheme.heading(fontSize: 28)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pemasukan bulan ini', style: AppTheme.body(fontSize: 12)),
                          Text(_currency.format(income), style: AppTheme.body(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Pengeluaran bulan ini', style: AppTheme.body(fontSize: 12)),
                          Text(_currency.format(expense), style: AppTheme.body(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Transaksi Terbaru', style: AppTheme.heading(fontSize: 18)),
          const SizedBox(height: 8),
          if (recentTransactions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text('Belum ada transaksi', style: AppTheme.body()),
            )
          else
            for (final t in recentTransactions.take(5))
              Card(
                child: ListTile(
                  title: Text(
                    (t.note?.isNotEmpty ?? false) ? t.note! : _labelFor(t.type),
                    style: AppTheme.body(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(DateFormat('d MMM yyyy, HH:mm').format(t.dateTime)),
                  trailing: Text(
                    _currency.format(t.amount),
                    style: AppTheme.body(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  String _labelFor(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return 'Pemasukan';
      case TransactionType.expense:
        return 'Pengeluaran';
      case TransactionType.transfer:
        return 'Transfer';
    }
  }
}
