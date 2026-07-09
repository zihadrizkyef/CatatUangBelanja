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
    this.icon = AppIcons.summary,
    this.message = 'Belum ada data untuk periode ini, Bun.',
  });

  final AppPalette palette;
  final String icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return EmptyState(palette: palette, icon: icon, iconSize: 42, title: message);
  }
}

@Preview(name: 'ChartEmptyState')
Widget previewChartEmptyState() {
  return ChartEmptyState(palette: AppPalette.light);
}
