import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart' as models;
import '../models/transaction.dart';
import '../repositories/finance_repository.dart';
import '../theme/app_colors.dart';
import '../widgets/donut_chart.dart';
import '../widgets/trend_chart.dart';
import 'budget_screen.dart';
import 'summary_view.dart';

/// Rangkuman tab container: period-scoped income/expense summary, category
/// breakdown donut, income-vs-expense trend, and (always calendar-month-scoped,
/// since [Budget] itself is monthly) budget progress + top-spending ranking —
/// all derived live from [FinanceRepository] and handed to [SummaryView].
class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  Period _period = Period.bulanan;

  DateTimeRange _currentRange(DateTime now) {
    switch (_period) {
      case Period.harian:
        final start = DateTime(now.year, now.month, now.day);
        return DateTimeRange(
          start: start,
          end: start.add(const Duration(days: 1)),
        );
      case Period.mingguan:
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(monday.year, monday.month, monday.day);
        return DateTimeRange(
          start: start,
          end: start.add(const Duration(days: 7)),
        );
      case Period.bulanan:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 1),
        );
      case Period.tahunan:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year + 1, 1, 1),
        );
    }
  }

  DateTimeRange _previousRange(DateTime now) {
    switch (_period) {
      case Period.harian:
        final start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 1));
        return DateTimeRange(
          start: start,
          end: start.add(const Duration(days: 1)),
        );
      case Period.mingguan:
        final cur = _currentRange(now);
        final start = cur.start.subtract(const Duration(days: 7));
        return DateTimeRange(start: start, end: cur.start);
      case Period.bulanan:
        final start = DateTime(now.year, now.month - 1, 1);
        return DateTimeRange(
          start: start,
          end: DateTime(now.year, now.month, 1),
        );
      case Period.tahunan:
        return DateTimeRange(
          start: DateTime(now.year - 1, 1, 1),
          end: DateTime(now.year, 1, 1),
        );
    }
  }

  List<SummaryBucket> _buckets(DateTime now, List<Transaction> txs) {
    int incomeIn(DateTime start, DateTime end) => txs
        .where(
          (t) =>
              t.type == TransactionType.income &&
              !t.dateTime.isBefore(start) &&
              t.dateTime.isBefore(end),
        )
        .fold(0, (s, t) => s + t.amount);
    int expenseIn(DateTime start, DateTime end) => txs
        .where(
          (t) =>
              t.type == TransactionType.expense &&
              !t.dateTime.isBefore(start) &&
              t.dateTime.isBefore(end),
        )
        .fold(0, (s, t) => s + t.amount);

    switch (_period) {
      case Period.harian:
        final dayStart = DateTime(now.year, now.month, now.day);
        return List.generate(6, (i) {
          final start = dayStart.add(Duration(hours: i * 4));
          final end = start.add(const Duration(hours: 4));
          return (
            label: start.hour.toString().padLeft(2, '0'),
            income: incomeIn(start, end),
            expense: expenseIn(start, end),
          );
        });
      case Period.mingguan:
        const dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
        final cur = _currentRange(now);
        return List.generate(7, (i) {
          final start = cur.start.add(Duration(days: i));
          final end = start.add(const Duration(days: 1));
          return (
            label: dayLabels[i],
            income: incomeIn(start, end),
            expense: expenseIn(start, end),
          );
        });
      case Period.bulanan:
        final cur = _currentRange(now);
        final weeks = (cur.end.difference(cur.start).inDays / 7).ceil();
        return List.generate(weeks, (i) {
          final start = cur.start.add(Duration(days: i * 7));
          final end = start.add(const Duration(days: 7)).isAfter(cur.end)
              ? cur.end
              : start.add(const Duration(days: 7));
          return (
            label: 'M${i + 1}',
            income: incomeIn(start, end),
            expense: expenseIn(start, end),
          );
        });
      case Period.tahunan:
        const monthLabels = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'Mei',
          'Jun',
          'Jul',
          'Agu',
          'Sep',
          'Okt',
          'Nov',
          'Des',
        ];
        return List.generate(12, (i) {
          final start = DateTime(now.year, i + 1, 1);
          final end = DateTime(now.year, i + 2, 1);
          return (
            label: monthLabels[i],
            income: incomeIn(start, end),
            expense: expenseIn(start, end),
          );
        });
    }
  }

  void _openBudgetScreen(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BudgetScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<FinanceRepository>();
    final now = DateTime.now();

    final current = _currentRange(now);
    final previous = _previousRange(now);
    final allTx = repository.transactions;

    bool inRange(Transaction t, DateTimeRange r) =>
        !t.dateTime.isBefore(r.start) && t.dateTime.isBefore(r.end);

    final currentTx = allTx.where((t) => inRange(t, current)).toList();
    final previousExpense = allTx
        .where((t) => t.type == TransactionType.expense && inRange(t, previous))
        .fold(0, (s, t) => s + t.amount);

    final income = currentTx
        .where((t) => t.type == TransactionType.income)
        .fold(0, (s, t) => s + t.amount);
    final expense = currentTx
        .where((t) => t.type == TransactionType.expense)
        .fold(0, (s, t) => s + t.amount);

    final hasComparisonData = !(previousExpense == 0 && expense == 0);
    final changePct = previousExpense == 0
        ? (expense == 0 ? 0 : 100)
        : ((expense - previousExpense) * 100 / previousExpense).round();
    final improved = changePct < 0;

    final byCategory = <String, int>{};
    for (final t in currentTx.where((t) => t.type == TransactionType.expense)) {
      final key = t.categoryId ?? '';
      byCategory[key] = (byCategory[key] ?? 0) + t.amount;
    }
    final sortedCategories = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final legendEntries = sortedCategories.take(5).toList();
    final othersTotal = sortedCategories.skip(5).fold(0, (s, e) => s + e.value);

    final legendData = <CategoryLegendEntry>[
      for (var i = 0; i < legendEntries.length; i++)
        (
          label:
              repository.categories
                  .where((c) => c.id == legendEntries[i].key)
                  .firstOrNull
                  ?.name ??
              'Lainnya',
          value: legendEntries[i].value,
          color: AppColors.legend[i % AppColors.legend.length],
        ),
      if (othersTotal > 0)
        (
          label: 'Lainnya',
          value: othersTotal,
          color:
              AppColors.legend[legendEntries.length % AppColors.legend.length],
        ),
    ];

    final buckets = _buckets(now, allTx);
    final budgetStatuses = repository.budgetStatuses;

    // Ranked independently of budgetStatuses (which only covers categories
    // with a budget set) — see PM-02: "Pengeluaran Terbesar" should reflect
    // actual spending, not budget existence.
    final topSpending = <CategorySpending>[
      for (final entry in sortedCategories)
        if (repository.categories.where((c) => c.id == entry.key).firstOrNull
            case final models.Category category?)
          (category: category, amount: entry.value),
    ];

    return SummaryView(
      period: _period,
      onPeriodChanged: (p) => setState(() => _period = p),
      income: income,
      expense: expense,
      changePct: changePct,
      improved: improved,
      hasComparisonData: hasComparisonData,
      legendData: legendData,
      buckets: buckets,
      budgetStatuses: budgetStatuses,
      topSpending: topSpending,
      onOpenBudget: () => _openBudgetScreen(context),
    );
  }
}
