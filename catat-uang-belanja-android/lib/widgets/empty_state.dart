import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'dashed_border_box.dart';
import 'openmoji_icon.dart';

/// Generic empty-state placeholder (icon + title, optional call-to-action
/// button) for any list/section that has no data yet — e.g. no transactions,
/// no wallets, no budgets. Two shapes per the mockups: [bordered] (default)
/// draws a bordered/tinted card, used for secondary sections (charts,
/// wallet/budget lists); non-bordered renders as a plain centered block,
/// used for the larger "belum ada transaksi" placeholders.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.palette,
    required this.icon,
    required this.title,
    this.iconSize = 56,
    this.bordered = true,
    this.buttonLabel,
    this.onButtonTap,
  });

  final AppPalette palette;
  final String icon;
  final String title;
  final double iconSize;
  final bool bordered;
  final String? buttonLabel;
  final VoidCallback? onButtonTap;

  @override
  Widget build(BuildContext context) {
    final hasButton = buttonLabel != null && onButtonTap != null;

    final card = Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: bordered ? 28 : 34, horizontal: 16),
      decoration: bordered ? BoxDecoration(color: palette.cardBg, borderRadius: BorderRadius.circular(16)) : null,
      child: Column(
        children: [
          OpenMojiIcon(icon, size: iconSize),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTheme.body(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: bordered ? palette.textPrimary : palette.textSecondary,
            ),
          ),
          if (hasButton) ...[
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onButtonTap,
              child: Text(
                buttonLabel!,
                style: AppTheme.body(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ],
      ),
    );

    if (!bordered) return card;
    return DashedBorderBox(color: palette.borderStrong, borderRadius: 16, child: card);
  }
}

@Preview(name: 'EmptyState · tanpa tombol')
Widget previewEmptyStateNoButton() {
  return EmptyState(
    palette: AppPalette.light,
    icon: AppIcons.emptyReceipt,
    title: 'Belum ada transaksi, Bun. Yuk catat yang pertama.',
  );
}

@Preview(name: 'EmptyState · dengan tombol')
Widget previewEmptyStateWithButton() {
  return EmptyState(
    palette: AppPalette.light,
    icon: AppIcons.budgetSeedling,
    title: 'Belum ada anggaran, Bun. Yuk mulai atur biar pengeluaran lebih terkontrol!',
    buttonLabel: '+ Buat Anggaran',
    onButtonTap: () {},
  );
}
