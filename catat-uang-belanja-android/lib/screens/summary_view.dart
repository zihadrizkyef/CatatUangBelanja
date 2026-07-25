import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:intl/intl.dart';

import '../models/budget.dart';
import '../models/budget_status.dart';
import '../models/category.dart' as models;
import '../models/icon_type.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/chart_empty_state.dart';
import '../widgets/donut_chart.dart';
import '../widgets/empty_state.dart';
import '../widgets/top_spending_row.dart';
import '../widgets/trend_chart.dart';
import '../widgets/openmoji_icon.dart';

final _currency = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
);

enum Period { harian, mingguan, bulanan, tahunan }

/// A category's total expense for the active period, ranked independently of
/// whether it has a budget set — used by "Pengeluaran Terbesar".
typedef CategorySpending = ({models.Category category, int amount});

extension PeriodLabel on Period {
  String get label => switch (this) {
    Period.harian => 'Harian',
    Period.mingguan => 'Mingguan',
    Period.bulanan => 'Bulanan',
    Period.tahunan => 'Tahunan',
  };
}

/// Pure Rangkuman layout: period selector, income/expense header, this-vs-last
/// comparison, expense breakdown donut, income/expense trend chart, budget
/// progress, and top-spending ranking. All data and callbacks come from the
/// [SummaryScreen] container — this widget never reads [FinanceRepository] or
/// [Navigator] itself.
class SummaryView extends StatelessWidget {
  const SummaryView({
    super.key,
    required this.period,
    required this.onPeriodChanged,
    required this.income,
    required this.expense,
    required this.changePct,
    required this.improved,
    required this.hasComparisonData,
    required this.legendData,
    required this.buckets,
    required this.budgetStatuses,
    required this.topSpending,
    required this.onOpenBudget,
  });

  final Period period;
  final ValueChanged<Period> onPeriodChanged;
  final int income;
  final int expense;
  final int changePct;
  final bool improved;

  /// False when both this period and the previous one have zero expense —
  /// there's nothing to meaningfully compare, so the badge shows a neutral
  /// message instead of a misleading "lebih banyak" on a fresh install.
  final bool hasComparisonData;
  final List<CategoryLegendEntry> legendData;
  final List<SummaryBucket> buckets;
  final List<BudgetStatus> budgetStatuses;
  final List<CategorySpending> topSpending;
  final VoidCallback onOpenBudget;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.accentHeaderOverlay,
      child: Scaffold(
        backgroundColor: palette.screenBg,
        body: SafeArea(
          top: false,
          bottom: false,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.of(context).padding.top + 22,
                  20,
                  26,
                ),
                color: AppColors.accent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rangkuman 📊',
                      style: AppTheme.heading(
                        fontSize: 21,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          '▲ ${_currency.format(income)}',
                          style: AppTheme.body(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Text(
                          '▼ ${_currency.format(expense)}',
                          style: AppTheme.body(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: palette.cardBg,
                    border: Border.all(color: palette.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      for (final p in Period.values)
                        Expanded(
                          child: Material(
                            color: period == p
                                ? AppColors.accent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(9),
                              onTap: () => onPeriodChanged(p),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Text(
                                  p.label,
                                  textAlign: TextAlign.center,
                                  style: AppTheme.body(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: period == p
                                        ? Colors.white
                                        : palette.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: palette.cardBg,
                    border: Border.all(color: palette.border),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${period.label} ini vs sebelumnya',
                            style: AppTheme.body(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: palette.textSecondary,
                            ),
                          ),
                          Text(
                            _currency.format(expense),
                            style: AppTheme.heading(
                              fontSize: 16,
                              color: palette.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (hasComparisonData)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${improved ? '▼' : '▲'} ${changePct.abs()}%',
                              style: AppTheme.body(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: improved
                                    ? AppColors.okBar
                                    : AppColors.accent,
                              ),
                            ),
                            Text(
                              improved ? 'lebih hemat' : 'lebih banyak dari sebelumnya',
                              style: AppTheme.body(
                                fontSize: 10.5,
                                color: palette.textSecondary,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          'Belum ada data untuk dibandingkan, Bun',
                          textAlign: TextAlign.end,
                          style: AppTheme.body(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: palette.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ringkasan Pengeluaran',
                      style: AppTheme.heading(
                        fontSize: 13,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (legendData.isEmpty)
                      ChartEmptyState(
                        palette: palette,
                        icon: AppIcons.emptyExpensePie,
                        message: 'Belum ada pengeluaran periode ini, Bun.',
                      )
                    else
                      DonutChart(
                        legendData: legendData,
                        centerLabel: '${period.label} ini',
                        palette: palette,
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tren Pemasukan vs Pengeluaran',
                      style: AppTheme.heading(
                        fontSize: 13,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (buckets.every(
                      (b) => b.income == 0 && b.expense == 0,
                    ))
                      ChartEmptyState(palette: palette, icon: AppIcons.emptyTrend)
                    else
                      Container(
                        padding: const EdgeInsets.fromLTRB(0, 12, 14, 8),
                        decoration: BoxDecoration(
                          color: palette.cardBg,
                          border: Border.all(color: palette.border),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TrendChart(buckets: buckets, palette: palette),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Anggaran Bulan Ini',
                          style: AppTheme.heading(
                            fontSize: 13,
                            color: palette.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: onOpenBudget,
                          child: Text(
                            'Kelola ›',
                            style: AppTheme.body(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (budgetStatuses.isEmpty)
                      EmptyState(
                        palette: palette,
                        icon: AppIcons.budgetSeedling,
                        iconSize: 42,
                        title: 'Belum ada anggaran, Bun. Yuk mulai atur biar pengeluaran lebih terkontrol!',
                        buttonLabel: '+ Buat Anggaran',
                        onButtonTap: onOpenBudget,
                      )
                    else
                      Column(
                        children: [
                          for (final b in budgetStatuses)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (AppIcons.byIconValue[b.category.iconValue] != null) ...[
                                        OpenMojiIcon(AppIcons.byIconValue[b.category.iconValue]!, size: 33),
                                        const SizedBox(width: 4),
                                      ],
                                      Expanded(
                                        child: Text(
                                          b.category.name,
                                          style: AppTheme.body(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: palette.textPrimary,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${_currency.format(b.used)}/${_currency.format(b.budget.limitAmount)}',
                                        style: AppTheme.body(
                                          fontSize: 12,
                                          color: palette.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(3),
                                    child: LinearProgressIndicator(
                                      value: b.pct.clamp(0, 100) / 100,
                                      minHeight: 5,
                                      backgroundColor: palette.warningBg,
                                      valueColor: AlwaysStoppedAnimation(
                                        b.pct >= 100
                                            ? AppColors.dangerBar
                                            : (b.pct >= 80
                                                  ? AppColors.warningBar
                                                  : AppColors.okBar),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengeluaran Terbesar',
                      style: AppTheme.heading(
                        fontSize: 13,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (topSpending.isEmpty)
                      EmptyState(
                        palette: palette,
                        icon: AppIcons.trophy,
                        iconSize: 42,
                        title: 'Belum ada pengeluaran untuk dirangking, Bun.',
                      )
                    else
                      for (var i = 0; i < topSpending.length; i++)
                        TopSpendingRow(
                          rank: i + 1,
                          category: topSpending[i].category,
                          amount: topSpending[i].amount,
                          palette: palette,
                        ),
                    if (improved) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: palette.screenBg,
                          border: Border.all(color: palette.borderStrong),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const OpenMojiIcon(AppIcons.appreciation, size: 34),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Mantap, Bun! Pengeluaran turun dibanding periode lalu. Pertahankan ya 💪',
                                style: AppTheme.body(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: palette.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
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

@Preview(name: 'SummaryView · dengan data')
Widget previewSummaryViewWithData() {
  return SummaryView(
    period: Period.bulanan,
    onPeriodChanged: (_) {},
    income: 3200000,
    expense: 1850000,
    changePct: -12,
    improved: true,
    hasComparisonData: true,
    legendData: [
      (label: 'Dapur', value: 850000, color: AppColors.legend[0]),
      (label: 'Transportasi', value: 400000, color: AppColors.legend[1]),
      (label: 'Lainnya', value: 600000, color: AppColors.legend[2]),
    ],
    buckets: const [
      (label: 'M1', income: 800000, expense: 500000),
      (label: 'M2', income: 800000, expense: 450000),
      (label: 'M3', income: 800000, expense: 400000),
      (label: 'M4', income: 800000, expense: 500000),
    ],
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
    topSpending: [
      (category: _previewCategory, amount: 850000),
      (
        category: models.Category(
          id: 'preview-category-2',
          name: 'Transportasi',
          type: models.CategoryType.expense,
          color: '#9B8FBD',
          iconType: IconType.system,
          iconValue: 'category_transport',
        ),
        amount: 400000,
      ),
    ],
    onOpenBudget: () {},
  );
}

@Preview(name: 'SummaryView · kosong')
Widget previewSummaryViewEmpty() {
  return SummaryView(
    period: Period.mingguan,
    onPeriodChanged: (_) {},
    income: 0,
    expense: 0,
    changePct: 0,
    improved: false,
    hasComparisonData: false,
    legendData: const [],
    buckets: const [
      (label: 'Sen', income: 0, expense: 0),
      (label: 'Sel', income: 0, expense: 0),
    ],
    budgetStatuses: const [],
    topSpending: const [],
    onOpenBudget: () {},
  );
}
