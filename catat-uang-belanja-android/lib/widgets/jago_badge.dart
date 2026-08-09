import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Small pill shown next to a transaction row's label when
/// `transaction.source == TransactionSource.emailSync` (integrasi-jago) —
/// used by both [HomeTransactionRow] and [TransactionHistoryRow] so the two
/// lists stay visually consistent, per doc's Semua-Transaksi/Beranda
/// consistency note (see UX-008).
class JagoBadge extends StatelessWidget {
  const JagoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Jago',
        style: AppTheme.body(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: AppColors.accent,
        ),
      ),
    );
  }
}

@Preview(name: 'JagoBadge')
Widget previewJagoBadge() {
  return const JagoBadge();
}
