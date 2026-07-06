import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

/// Beranda's empty state for the "Transaksi Terbaru" section.
class EmptyTransactionsCard extends StatelessWidget {
  const EmptyTransactionsCard({super.key, required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 34),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            const TwemojiIcon(AppIcons.emptyReceipt, size: 32),
            const SizedBox(height: 8),
            Text(
              'Belum ada transaksi, Bun. Yuk catat yang pertama.',
              textAlign: TextAlign.center,
              style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: palette.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

@Preview(name: 'EmptyTransactionsCard')
Widget previewEmptyTransactionsCard() {
  return EmptyTransactionsCard(palette: AppPalette.light);
}
