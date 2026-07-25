import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'dashed_line.dart';

/// Dashed-bordered strip above Semua Transaksi's grouped list: how many
/// transactions match the current filters, and their net (income − expense,
/// transfers excluded per doc 4.3).
class TransactionSummaryBar extends StatelessWidget {
  const TransactionSummaryBar({super.key, required this.countText, required this.netText, required this.netColor, required this.palette});

  final String countText;
  final String netText;
  final Color netColor;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DashedLine(color: palette.border),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Text(countText, style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: palette.textSecondary)),
              const Spacer(),
              Text(netText, style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: netColor)),
            ],
          ),
        ),
        DashedLine(color: palette.border),
      ],
    );
  }
}

@Preview(name: 'TransactionSummaryBar')
Widget previewTransactionSummaryBar() {
  return TransactionSummaryBar(
    countText: '5 transaksi',
    netText: '+Rp6.325.000',
    netColor: AppColors.gold,
    palette: AppPalette.light,
  );
}
