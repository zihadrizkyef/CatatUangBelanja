import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'twemoji_icon.dart';

/// Generic empty-state placeholder (icon + title, optional call-to-action
/// button) for any list/section that has no data yet — e.g. no transactions,
/// no wallets, no budgets. Doesn't add its own outer padding or decoration
/// so callers that need a bordered "card" look (see `ChartEmptyState`) or
/// extra spacing wrap it themselves.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.palette,
    required this.icon,
    required this.title,
    this.iconSize = 56,
    this.buttonLabel,
    this.onButtonTap,
  });

  final AppPalette palette;
  final String icon;
  final String title;
  final double iconSize;
  final String? buttonLabel;
  final VoidCallback? onButtonTap;

  @override
  Widget build(BuildContext context) {
    final hasButton = buttonLabel != null && onButtonTap != null;

    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
          TwemojiIcon(icon, size: iconSize),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTheme.body(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: hasButton ? palette.textPrimary : palette.textSecondary,
            ),
          ),
          if (hasButton) ...[
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.accent),
              onPressed: onButtonTap,
              child: Text(buttonLabel!),
            ),
          ],
        ],
      ),
    );
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
