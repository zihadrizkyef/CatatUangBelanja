import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'legend_dot.dart';

/// One point on Rangkuman's income-vs-expense trend chart — a period bucket
/// (an hour range, day, week, or month depending on the selected period)
/// with its labeled totals.
typedef SummaryBucket = ({String label, int income, int expense});

String _compactRupiah(int value) {
  if (value >= 1000000) {
    final millions = value / 1000000;
    return '${millions == millions.roundToDouble() ? millions.toStringAsFixed(0) : millions.toStringAsFixed(1)}jt';
  }
  if (value >= 1000) return '${(value / 1000).round()}rb';
  return value.toString();
}

/// Rangkuman's "Tren Pemasukan vs Pengeluaran" chart: a Y axis, the
/// income/expense line series drawn by [_TrendPainter], the bucket labels
/// along the X axis, and the income/expense legend.
class TrendChart extends StatelessWidget {
  const TrendChart({super.key, required this.buckets, required this.palette});

  final List<SummaryBucket> buckets;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final maxValue = buckets.fold(
      0,
      (m, b) => math.max(m, math.max(b.income, b.expense)),
    );
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
                  Text(
                    _compactRupiah(axisMax),
                    style: AppTheme.body(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: palette.textSecondary,
                    ),
                  ),
                  Text(
                    _compactRupiah((axisMax / 2).round()),
                    style: AppTheme.body(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: palette.textSecondary,
                    ),
                  ),
                  Text(
                    '0',
                    style: AppTheme.body(
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SizedBox(
                height: 70,
                child: CustomPaint(
                  painter: _TrendPainter(
                    buckets: buckets,
                    axisMax: axisMax,
                    border: palette.border,
                    borderStrong: palette.borderStrong,
                  ),
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 40),
          child: Row(
            children: [
              for (final b in buckets)
                Expanded(
                  child: Text(
                    b.label,
                    textAlign: TextAlign.center,
                    style: AppTheme.body(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 40, top: 8),
          child: Row(
            children: [
              LegendDot(
                color: AppColors.gold,
                label: 'Pemasukan',
                palette: palette,
              ),
              const SizedBox(width: 14),
              LegendDot(
                color: AppColors.accent,
                label: 'Pengeluaran',
                palette: palette,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.buckets,
    required this.axisMax,
    required this.border,
    required this.borderStrong,
  });

  final List<SummaryBucket> buckets;
  final int axisMax;
  final Color border;
  final Color borderStrong;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()..strokeWidth = 1;
    gridPaint.color = border;
    canvas.drawLine(
      Offset(0, size.height * 0.14),
      Offset(size.width, size.height * 0.14),
      gridPaint,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.51),
      Offset(size.width, size.height * 0.51),
      gridPaint,
    );
    gridPaint.color = borderStrong;
    canvas.drawLine(
      Offset(0, size.height * 0.77),
      Offset(size.width, size.height * 0.77),
      gridPaint,
    );

    if (buckets.isEmpty) return;
    final n = buckets.length;
    Offset pointFor(int i, int value) {
      final x = n == 1 ? size.width / 2 : i * (size.width / (n - 1));
      final y = size.height - (value / axisMax) * size.height;
      return Offset(x, y.clamp(0, size.height));
    }

    void drawSeries(int Function(SummaryBucket) selector, Color color) {
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
  bool shouldRepaint(_TrendPainter oldDelegate) =>
      oldDelegate.buckets != buckets || oldDelegate.axisMax != axisMax;
}

@Preview(name: 'TrendChart')
Widget previewTrendChart() {
  return TrendChart(
    buckets: const [
      (label: 'Sen', income: 200000, expense: 120000),
      (label: 'Sel', income: 0, expense: 80000),
      (label: 'Rab', income: 150000, expense: 60000),
      (label: 'Kam', income: 0, expense: 40000),
      (label: 'Jum', income: 300000, expense: 200000),
      (label: 'Sab', income: 0, expense: 90000),
      (label: 'Min', income: 0, expense: 30000),
    ],
    palette: AppPalette.light,
  );
}
