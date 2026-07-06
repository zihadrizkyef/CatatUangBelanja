import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

/// Beranda's "all budgets healthy" callout — shown when at least one budget
/// exists and none is at/above 80% usage.
class SafeBudgetBanner extends StatelessWidget {
  const SafeBudgetBanner({super.key, required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: palette.safeBg, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          const TwemojiIcon(AppIcons.budgetSafe, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Semua anggaran masih aman, Bun. Mantap!',
              style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: palette.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

@Preview(name: 'SafeBudgetBanner')
Widget previewSafeBudgetBanner() {
  return SafeBudgetBanner(palette: AppPalette.light);
}
