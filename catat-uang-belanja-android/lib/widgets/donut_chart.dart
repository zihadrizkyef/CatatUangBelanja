import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// One category's slice in Rangkuman's expense-breakdown donut, plus its
/// paired legend row — a display label ("Lainnya" for the aggregated tail of
/// categories past the top 5), its amount, and the color used for both the
/// slice and the legend dot.
typedef CategoryLegendEntry = ({String label, int value, Color color});

String _compactRupiah(int value) {
  if (value >= 1000000) {
    final millions = value / 1000000;
    return '${millions == millions.roundToDouble() ? millions.toStringAsFixed(0) : millions.toStringAsFixed(1)}jt';
  }
  if (value >= 1000) return '${(value / 1000).round()}rb';
  return value.toString();
}

/// Rangkuman's "Ringkasan Pengeluaran" donut: a ring chart of [legendData]
/// slices drawn by [_DonutPainter] with the period total centered inside,
/// plus a legend list showing each category's amount and share of the total.
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.legendData,
    required this.centerLabel,
    required this.palette,
  });

  final List<CategoryLegendEntry> legendData;
  final String centerLabel;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final total = legendData.fold(0, (s, e) => s + e.value);

    return Row(
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
                  Text(
                    centerLabel,
                    style: AppTheme.body(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: palette.textSecondary,
                    ),
                  ),
                  Text(
                    'Rp${_compactRupiah(total)}',
                    style: AppTheme.heading(
                      fontSize: 10,
                      color: palette.textPrimary,
                    ),
                  ),
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
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: l.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          l.label,
                          style: AppTheme.body(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${total == 0 ? 0 : (l.value * 100 / total).round()}%',
                        style: AppTheme.body(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: palette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
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
  bool shouldRepaint(_DonutPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.colors != colors;
}

@Preview(name: 'DonutChart')
Widget previewDonutChart() {
  return DonutChart(
    legendData: [
      (label: 'Dapur', value: 450000, color: AppColors.legend[0]),
      (label: 'Transportasi', value: 200000, color: AppColors.legend[1]),
      (label: 'Lainnya', value: 100000, color: AppColors.legend[2]),
    ],
    centerLabel: 'Bulanan ini',
    palette: AppPalette.light,
  );
}
