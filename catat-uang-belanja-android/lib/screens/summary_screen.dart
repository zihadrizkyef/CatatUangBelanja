import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/budget_status.dart';
import '../models/transaction.dart';
import '../repositories/finance_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'budget_screen.dart';

final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

String _compactRupiah(int value) {
  if (value >= 1000000) {
    final millions = value / 1000000;
    return '${millions == millions.roundToDouble() ? millions.toStringAsFixed(0) : millions.toStringAsFixed(1)}jt';
  }
  if (value >= 1000) return '${(value / 1000).round()}rb';
  return value.toString();
}

enum _Period { harian, mingguan, bulanan, tahunan }

extension on _Period {
  String get label => switch (this) {
        _Period.harian => 'Harian',
        _Period.mingguan => 'Mingguan',
        _Period.bulanan => 'Bulanan',
        _Period.tahunan => 'Tahunan',
      };
}

class _Bucket {
  const _Bucket(this.label, this.income, this.expense);
  final String label;
  final int income;
  final int expense;
}

/// Rangkuman tab: period-scoped income/expense summary, category breakdown
/// donut, income-vs-expense trend, and (always calendar-month-scoped, since
/// [Budget] itself is monthly) budget progress + top-spending ranking — all
/// computed live from [FinanceRepository].
class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  _Period _period = _Period.bulanan;

  DateTimeRange _currentRange(DateTime now) {
    switch (_period) {
      case _Period.harian:
        final start = DateTime(now.year, now.month, now.day);
        return DateTimeRange(start: start, end: start.add(const Duration(days: 1)));
      case _Period.mingguan:
        final monday = now.subtract(Duration(days: now.weekday - 1));
        final start = DateTime(monday.year, monday.month, monday.day);
        return DateTimeRange(start: start, end: start.add(const Duration(days: 7)));
      case _Period.bulanan:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: DateTime(now.year, now.month + 1, 1));
      case _Period.tahunan:
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: DateTime(now.year + 1, 1, 1));
    }
  }

  DateTimeRange _previousRange(DateTime now) {
    switch (_period) {
      case _Period.harian:
        final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
        return DateTimeRange(start: start, end: start.add(const Duration(days: 1)));
      case _Period.mingguan:
        final cur = _currentRange(now);
        final start = cur.start.subtract(const Duration(days: 7));
        return DateTimeRange(start: start, end: cur.start);
      case _Period.bulanan:
        final start = DateTime(now.year, now.month - 1, 1);
        return DateTimeRange(start: start, end: DateTime(now.year, now.month, 1));
      case _Period.tahunan:
        return DateTimeRange(start: DateTime(now.year - 1, 1, 1), end: DateTime(now.year, 1, 1));
    }
  }

  List<_Bucket> _buckets(DateTime now, List<Transaction> txs) {
    int incomeIn(DateTime start, DateTime end) => txs
        .where((t) => t.type == TransactionType.income && !t.dateTime.isBefore(start) && t.dateTime.isBefore(end))
        .fold(0, (s, t) => s + t.amount);
    int expenseIn(DateTime start, DateTime end) => txs
        .where((t) => t.type == TransactionType.expense && !t.dateTime.isBefore(start) && t.dateTime.isBefore(end))
        .fold(0, (s, t) => s + t.amount);

    switch (_period) {
      case _Period.harian:
        final dayStart = DateTime(now.year, now.month, now.day);
        return List.generate(6, (i) {
          final start = dayStart.add(Duration(hours: i * 4));
          final end = start.add(const Duration(hours: 4));
          return _Bucket(start.hour.toString().padLeft(2, '0'), incomeIn(start, end), expenseIn(start, end));
        });
      case _Period.mingguan:
        const dayLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
        final cur = _currentRange(now);
        return List.generate(7, (i) {
          final start = cur.start.add(Duration(days: i));
          final end = start.add(const Duration(days: 1));
          return _Bucket(dayLabels[i], incomeIn(start, end), expenseIn(start, end));
        });
      case _Period.bulanan:
        final cur = _currentRange(now);
        final weeks = (cur.end.difference(cur.start).inDays / 7).ceil();
        return List.generate(weeks, (i) {
          final start = cur.start.add(Duration(days: i * 7));
          final end = start.add(const Duration(days: 7)).isAfter(cur.end) ? cur.end : start.add(const Duration(days: 7));
          return _Bucket('M${i + 1}', incomeIn(start, end), expenseIn(start, end));
        });
      case _Period.tahunan:
        const monthLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
        return List.generate(12, (i) {
          final start = DateTime(now.year, i + 1, 1);
          final end = DateTime(now.year, i + 2, 1);
          return _Bucket(monthLabels[i], incomeIn(start, end), expenseIn(start, end));
        });
    }
  }

  void _openBudgetScreen(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BudgetScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<FinanceRepository>();
    final palette = AppPalette.of(context);
    final now = DateTime.now();

    final current = _currentRange(now);
    final previous = _previousRange(now);
    final allTx = repository.transactions;

    bool inRange(Transaction t, DateTimeRange r) => !t.dateTime.isBefore(r.start) && t.dateTime.isBefore(r.end);

    final currentTx = allTx.where((t) => inRange(t, current)).toList();
    final previousExpense =
        allTx.where((t) => t.type == TransactionType.expense && inRange(t, previous)).fold(0, (s, t) => s + t.amount);

    final income = currentTx.where((t) => t.type == TransactionType.income).fold(0, (s, t) => s + t.amount);
    final expense = currentTx.where((t) => t.type == TransactionType.expense).fold(0, (s, t) => s + t.amount);

    final changePct = previousExpense == 0
        ? (expense == 0 ? 0 : 100)
        : ((expense - previousExpense) * 100 / previousExpense).round();
    final improved = changePct < 0;

    final byCategory = <String, int>{};
    for (final t in currentTx.where((t) => t.type == TransactionType.expense)) {
      final key = t.categoryId ?? '';
      byCategory[key] = (byCategory[key] ?? 0) + t.amount;
    }
    final sortedCategories = byCategory.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final legendEntries = sortedCategories.take(5).toList();
    final othersTotal = sortedCategories.skip(5).fold(0, (s, e) => s + e.value);

    final legendData = <({String label, int value, Color color})>[
      for (var i = 0; i < legendEntries.length; i++)
        (
          label: repository.categories.where((c) => c.id == legendEntries[i].key).firstOrNull?.name ?? 'Lainnya',
          value: legendEntries[i].value,
          color: AppColors.legend[i % AppColors.legend.length],
        ),
      if (othersTotal > 0) (label: 'Lainnya', value: othersTotal, color: AppColors.legend[legendEntries.length % AppColors.legend.length]),
    ];

    final buckets = _buckets(now, allTx);
    final budgetStatuses = repository.budgetStatuses;

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
                  Text('Rangkuman 📊', style: AppTheme.heading(fontSize: 21, color: Colors.white)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text('▲ ${_currency.format(income)}', style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                      const SizedBox(width: 18),
                      Text('▼ ${_currency.format(expense)}', style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: palette.cardBg, border: Border.all(color: palette.border), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    for (final p in _Period.values)
                      Expanded(
                        child: Material(
                          color: _period == p ? AppColors.accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(9),
                            onTap: () => setState(() => _period = p),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                p.label,
                                textAlign: TextAlign.center,
                                style: AppTheme.body(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _period == p ? Colors.white : palette.textSecondary,
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
                decoration: BoxDecoration(color: palette.cardBg, border: Border.all(color: palette.border), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${_period.label} ini vs sebelumnya', style: AppTheme.body(fontSize: 11, fontWeight: FontWeight.bold, color: palette.textSecondary)),
                        Text(_currency.format(expense), style: AppTheme.heading(fontSize: 16, color: palette.textPrimary)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${improved ? '▼' : '▲'} ${changePct.abs()}%',
                          style: AppTheme.body(fontSize: 15, fontWeight: FontWeight.bold, color: improved ? AppColors.okBar : AppColors.accent),
                        ),
                        Text(improved ? 'lebih hemat' : 'lebih boros', style: AppTheme.body(fontSize: 10.5, color: palette.textSecondary)),
                      ],
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
                  Text('Ringkasan Pengeluaran', style: AppTheme.heading(fontSize: 13, color: palette.textPrimary)),
                  const SizedBox(height: 10),
                  if (legendData.isEmpty)
                    Text('Belum ada pengeluaran periode ini.', style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: palette.textSecondary))
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 108,
                          height: 108,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(108, 108),
                                painter: _DonutPainter(
                                  values: [for (final l in legendData) l.value.toDouble()],
                                  colors: [for (final l in legendData) l.color],
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('${_period.label} ini', style: AppTheme.body(fontSize: 9, fontWeight: FontWeight.bold, color: palette.textSecondary)),
                                  Text(_compactRupiahLabel(expense), style: AppTheme.heading(fontSize: 10, color: palette.textPrimary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              for (final l in legendData)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                                  child: Row(
                                    children: [
                                      Container(width: 9, height: 9, decoration: BoxDecoration(color: l.color, shape: BoxShape.circle)),
                                      const SizedBox(width: 6),
                                      Expanded(child: Text(l.label, style: AppTheme.body(fontSize: 11, fontWeight: FontWeight.bold, color: palette.textPrimary))),
                                      Text(
                                        '${(l.value * 100 / expense).round()}%',
                                        style: AppTheme.body(fontSize: 11, fontWeight: FontWeight.bold, color: palette.textSecondary),
                                      ),
                                    ],
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
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tren Pemasukan vs Pengeluaran', style: AppTheme.heading(fontSize: 13, color: palette.textPrimary)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.fromLTRB(0, 12, 14, 8),
                    decoration: BoxDecoration(color: palette.cardBg, border: Border.all(color: palette.border), borderRadius: BorderRadius.circular(16)),
                    child: _TrendChart(buckets: buckets, palette: palette),
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
                      Text('Anggaran Bulan Ini', style: AppTheme.heading(fontSize: 13, color: palette.textPrimary)),
                      TextButton(
                        onPressed: () => _openBudgetScreen(context),
                        child: Text('Kelola ›', style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent)),
                      ),
                    ],
                  ),
                  if (budgetStatuses.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: palette.cardBg, border: Border.all(color: palette.borderStrong, style: BorderStyle.solid), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          const TwemojiIcon(AppIcons.budgetSeedling, size: 30),
                          const SizedBox(height: 8),
                          Text(
                            'Belum ada anggaran, Bun. Yuk mulai atur biar pengeluaran lebih terkontrol!',
                            textAlign: TextAlign.center,
                            style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: palette.textPrimary),
                          ),
                          const SizedBox(height: 10),
                          FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
                            onPressed: () => _openBudgetScreen(context),
                            child: const Text('+ Buat Anggaran'),
                          ),
                        ],
                      ),
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
                                    Expanded(
                                      child: Text(b.category.name, style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: palette.textPrimary)),
                                    ),
                                    Text(
                                      '${_currency.format(b.used)}/${_currency.format(b.budget.limitAmount)}',
                                      style: AppTheme.body(fontSize: 12, color: palette.textSecondary),
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
                                    valueColor: AlwaysStoppedAnimation(b.pct >= 100 ? AppColors.dangerBar : (b.pct >= 80 ? AppColors.warningBar : AppColors.okBar)),
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
                  Text('Pengeluaran Terbesar', style: AppTheme.heading(fontSize: 13, color: palette.textPrimary)),
                  const SizedBox(height: 10),
                  if (budgetStatuses.isEmpty)
                    Text('Belum ada anggaran untuk dirangking.', style: AppTheme.body(fontSize: 13, color: palette.textSecondary))
                  else
                    for (var i = 0; i < budgetStatuses.length; i++)
                      _TopSpendingRow(rank: i + 1, status: budgetStatuses[i], palette: palette),
                  if (improved) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: palette.screenBg, border: Border.all(color: palette.borderStrong), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          const TwemojiIcon(AppIcons.appreciation, size: 24),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Mantap, Bun! Pengeluaran turun dibanding periode lalu. Pertahankan ya 💪',
                              style: AppTheme.body(fontSize: 12.5, fontWeight: FontWeight.bold, color: palette.textPrimary),
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
    );
  }

  String _compactRupiahLabel(int value) => 'Rp${_compactRupiah(value)}';
}

class _TopSpendingRow extends StatelessWidget {
  const _TopSpendingRow({required this.rank, required this.status, required this.palette});

  final int rank;
  final BudgetStatus status;
  final AppPalette palette;

  static const _medals = [AppIcons.medal1, AppIcons.medal2, AppIcons.medal3];

  @override
  Widget build(BuildContext context) {
    final iconAsset = AppIcons.byIconValue[status.category.iconValue];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: palette.cardBg, border: Border.all(color: palette.border), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: rank <= 3
                ? TwemojiIcon(_medals[rank - 1], size: 18)
                : Text('$rank.', style: AppTheme.heading(fontSize: 14, color: palette.borderStrong)),
          ),
          const SizedBox(width: 8),
          if (iconAsset != null) TwemojiIcon(iconAsset, size: 17),
          const SizedBox(width: 10),
          Expanded(child: Text(status.category.name, style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: palette.textPrimary))),
          Text(_currency.format(status.used), style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.peach)),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.values, required this.colors});

  final List<double> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold(0.0, (a, b) => a + b);
    if (total <= 0) return;
    final strokeWidth = size.width * 0.18;
    final radius = (size.width - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * 2 * math.pi;
      paint.color = colors[i % colors.length];
      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) => oldDelegate.values != values || oldDelegate.colors != colors;
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.buckets, required this.palette});

  final List<_Bucket> buckets;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final maxValue = buckets.fold(0, (m, b) => math.max(m, math.max(b.income, b.expense)));
    final axisMax = maxValue == 0 ? 100000 : maxValue;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 40,
              height: 70,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_compactRupiah(axisMax), style: AppTheme.body(fontSize: 8, fontWeight: FontWeight.bold, color: palette.textSecondary)),
                  Text(_compactRupiah((axisMax / 2).round()), style: AppTheme.body(fontSize: 8, fontWeight: FontWeight.bold, color: palette.textSecondary)),
                  Text('0', style: AppTheme.body(fontSize: 8, fontWeight: FontWeight.bold, color: palette.textSecondary)),
                ],
              ),
            ),
            Expanded(
              child: SizedBox(
                height: 70,
                child: CustomPaint(
                  painter: _TrendPainter(buckets: buckets, axisMax: axisMax, border: palette.border, borderStrong: palette.borderStrong),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 40),
          child: Row(
            children: [
              for (final b in buckets) Expanded(child: Text(b.label, textAlign: TextAlign.center, style: AppTheme.body(fontSize: 9, fontWeight: FontWeight.bold, color: palette.textSecondary))),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 40, top: 8),
          child: Row(
            children: [
              _LegendDot(color: AppColors.gold, label: 'Pemasukan', palette: palette),
              const SizedBox(width: 14),
              _LegendDot(color: AppColors.accent, label: 'Pengeluaran', palette: palette),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label, required this.palette});

  final Color color;
  final String label;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: AppTheme.body(fontSize: 11, fontWeight: FontWeight.bold, color: palette.textPrimary)),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({required this.buckets, required this.axisMax, required this.border, required this.borderStrong});

  final List<_Bucket> buckets;
  final int axisMax;
  final Color border;
  final Color borderStrong;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()..strokeWidth = 1;
    gridPaint.color = border;
    canvas.drawLine(Offset(0, size.height * 0.14), Offset(size.width, size.height * 0.14), gridPaint);
    canvas.drawLine(Offset(0, size.height * 0.51), Offset(size.width, size.height * 0.51), gridPaint);
    gridPaint.color = borderStrong;
    canvas.drawLine(Offset(0, size.height * 0.77), Offset(size.width, size.height * 0.77), gridPaint);

    if (buckets.isEmpty) return;
    final n = buckets.length;
    Offset pointFor(int i, int value) {
      final x = n == 1 ? size.width / 2 : i * (size.width / (n - 1));
      final y = size.height - (value / axisMax) * size.height;
      return Offset(x, y.clamp(0, size.height));
    }

    void drawSeries(int Function(_Bucket) selector, Color color) {
      final path = Path();
      for (var i = 0; i < n; i++) {
        final p = pointFor(i, selector(buckets[i]));
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    drawSeries((b) => b.income, AppColors.gold);
    drawSeries((b) => b.expense, AppColors.accent);
  }

  @override
  bool shouldRepaint(_TrendPainter oldDelegate) => oldDelegate.buckets != buckets || oldDelegate.axisMax != axisMax;
}
