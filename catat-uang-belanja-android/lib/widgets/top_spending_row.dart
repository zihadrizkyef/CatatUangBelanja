import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:intl/intl.dart';

import '../models/budget.dart';
import '../models/budget_status.dart';
import '../models/category.dart' as models;
import '../models/icon_type.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'openmoji_icon.dart';

final _currency = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
);

/// A single ranked row in Rangkuman's "Pengeluaran Terbesar" list — a medal
/// for the top 3 [rank]s, otherwise a plain ordinal, plus the category's icon,
/// name, and amount spent this period.
class TopSpendingRow extends StatelessWidget {
  const TopSpendingRow({
    super.key,
    required this.rank,
    required this.status,
    required this.palette,
  });

  final int rank;
  final BudgetStatus status;
  final AppPalette palette;

  static const _medals = [AppIcons.medal1, AppIcons.medal2, AppIcons.medal3];

  @override
  Widget build(BuildContext context) {
    final iconAsset = AppIcons.byIconValue[status.category.iconValue];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.cardBg,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: rank <= 3
                ? OpenMojiIcon(_medals[rank - 1], size: 22)
                : Text(
                    '$rank.',
                    style: AppTheme.heading(
                      fontSize: 14,
                      color: palette.borderStrong,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          if (iconAsset != null) OpenMojiIcon(iconAsset, size: 31),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              status.category.name,
              style: AppTheme.body(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: palette.textPrimary,
              ),
            ),
          ),
          Text(
            _currency.format(status.used),
            style: AppTheme.body(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.peach,
            ),
          ),
        ],
      ),
    );
  }
}

final _previewCategory = models.Category(
  id: 'preview-category',
  name: 'Dapur',
  type: models.CategoryType.expense,
  color: '#E8637C',
  iconType: IconType.system,
  iconValue: 'category_kitchen',
);

@Preview(name: 'TopSpendingRow · rank 1 (medali)')
Widget previewTopSpendingRowMedal() {
  return TopSpendingRow(
    rank: 1,
    status: BudgetStatus(
      category: _previewCategory,
      budget: Budget(
        id: 'preview-budget',
        categoryId: 'preview-category',
        limitAmount: 1000000,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
      used: 850000,
      pct: 85,
    ),
    palette: AppPalette.light,
  );
}

@Preview(name: 'TopSpendingRow · rank 4 (ordinal)')
Widget previewTopSpendingRowOrdinal() {
  return TopSpendingRow(
    rank: 4,
    status: BudgetStatus(
      category: _previewCategory,
      budget: Budget(
        id: 'preview-budget',
        categoryId: 'preview-category',
        limitAmount: 1000000,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ),
      used: 250000,
      pct: 25,
    ),
    palette: AppPalette.light,
  );
}
