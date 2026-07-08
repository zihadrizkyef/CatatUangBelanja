import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'empty_state.dart';

/// Shared empty state for Rangkuman's charts (donut breakdown, trend line)
/// when there's no transaction data yet for the selected period.
class ChartEmptyState extends StatelessWidget {
  const ChartEmptyState({
    super.key,
    required this.palette,
    this.message = 'Belum ada data untuk periode ini, Bun.',
  });

  final AppPalette palette;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: palette.cardBg,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: EmptyState(palette: palette, icon: AppIcons.summary, iconSize: 52, title: message),
    );
  }
}

@Preview(name: 'ChartEmptyState')
Widget previewChartEmptyState() {
  return ChartEmptyState(palette: AppPalette.light);
}
