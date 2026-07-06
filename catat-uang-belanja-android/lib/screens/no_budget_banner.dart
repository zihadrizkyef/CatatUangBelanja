import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

/// Beranda's "no budgets yet" callout, tappable to jump into [BudgetScreen].
class NoBudgetBanner extends StatelessWidget {
  const NoBudgetBanner({super.key, required this.palette, required this.onTap});

  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.chipNeutral,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(top: 8, bottom: 8),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const TwemojiIcon(AppIcons.budgetTarget, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Belum ada anggaran. Yuk buat yang pertama.',
                  style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: palette.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@Preview(name: 'NoBudgetBanner')
Widget previewNoBudgetBanner() {
  return NoBudgetBanner(palette: AppPalette.light, onTap: () {});
}
