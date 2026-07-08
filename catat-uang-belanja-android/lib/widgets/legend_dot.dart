import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Small colored dot + label used under Rangkuman's trend chart to label the
/// income/expense series (e.g. "Pemasukan"/"Pengeluaran").
class LegendDot extends StatelessWidget {
  const LegendDot({
    super.key,
    required this.color,
    required this.label,
    required this.palette,
  });

  final Color color;
  final String label;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTheme.body(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: palette.textPrimary,
          ),
        ),
      ],
    );
  }
}

@Preview(name: 'LegendDot')
Widget previewLegendDot() {
  return LegendDot(
    color: AppColors.gold,
    label: 'Pemasukan',
    palette: AppPalette.light,
  );
}
