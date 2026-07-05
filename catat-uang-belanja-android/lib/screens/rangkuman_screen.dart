import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/budget.dart';
import '../models/category.dart' as models;
import '../repositories/finance_repository.dart';
import '../theme/app_theme.dart';

final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

class RangkumanScreen extends StatelessWidget {
  const RangkumanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<FinanceRepository>();
    final now = DateTime.now();

    final expenseCategories = repository.categories.where((c) => c.type == models.CategoryType.expense);

    final spendingByCategory = <models.Category, int>{
      for (final category in expenseCategories) category: repository.budgetUsageThisMonth(category.id),
    }..removeWhere((_, amount) => amount == 0);

    final sortedEntries = spendingByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Rangkuman ${DateFormat('MMMM yyyy', 'id_ID').format(now)}', style: AppTheme.heading(fontSize: 22)),
          const SizedBox(height: 16),
          Text('Pengeluaran Terbesar Bulan Ini', style: AppTheme.heading(fontSize: 16)),
          const SizedBox(height: 8),
          if (sortedEntries.isEmpty)
            Text('Belum ada pengeluaran bulan ini', style: AppTheme.body())
          else
            for (final entry in sortedEntries)
              Card(
                child: ListTile(
                  title: Text(entry.key.name, style: AppTheme.body(fontWeight: FontWeight.bold)),
                  subtitle: _budgetSubtitle(repository, entry.key.id, entry.value),
                  trailing: Text(_currency.format(entry.value)),
                ),
              ),
        ],
      ),
    );
  }

  Widget? _budgetSubtitle(FinanceRepository repository, String categoryId, int spent) {
    Budget? budget;
    for (final b in repository.budgets) {
      if (b.categoryId == categoryId) {
        budget = b;
        break;
      }
    }
    if (budget == null) return null;
    return Text('${_currency.format(spent)} dari ${_currency.format(budget.limitAmount)}');
  }
}
