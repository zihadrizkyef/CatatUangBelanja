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

final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

/// A single row in the Anggaran list: category icon/name, usage vs. limit, a
/// progress bar colored by [BudgetStatus.pct], and a footer showing when the
/// period resets plus a manual "Reset Sekarang" action (doc 4.4).
class BudgetRow extends StatelessWidget {
  const BudgetRow({super.key, required this.status, required this.palette, required this.onTap, required this.onReset});

  final BudgetStatus status;
  final AppPalette palette;
  final VoidCallback onTap;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final clampedPct = status.pct.clamp(0, 100);
    final barColor = status.pct >= 100
        ? AppColors.dangerBar
        : (status.pct >= 80 ? AppColors.warningBar : AppColors.okBar);
    final iconAsset = AppIcons.byIconValue[status.category.iconValue];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.cardBg,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (iconAsset != null) OpenMojiIcon(iconAsset, size: 51),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          status.category.name,
                          style: AppTheme.body(fontSize: 14, fontWeight: FontWeight.bold, color: palette.textPrimary),
                        ),
                      ),
                      Text('›', style: TextStyle(fontSize: 16, color: palette.borderStrong)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${_currency.format(status.used)} dari ${_currency.format(status.budget.limitAmount)}',
                        style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: palette.textSecondary),
                      ),
                      const Spacer(),
                      Text('$clampedPct%', style: AppTheme.heading(fontSize: 13, color: barColor)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: clampedPct / 100,
                      minHeight: 6,
                      backgroundColor: palette.warningBg,
                      valueColor: AlwaysStoppedAnimation(barColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: palette.border))),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    status.resetLabel,
                    style: AppTheme.body(fontSize: 11, fontWeight: FontWeight.bold, color: palette.textSecondary),
                  ),
                ),
                Material(
                  color: palette.chipNeutral,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: onReset,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Text(
                        '↻ Reset Sekarang',
                        style: AppTheme.body(fontSize: 11, fontWeight: FontWeight.bold, color: palette.textPrimary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

@Preview(name: 'BudgetRow')
Widget previewBudgetRow() {
  return BudgetRow(
    status: BudgetStatus(
      category: const models.Category(
        id: 'preview-category',
        name: 'Dapur',
        type: models.CategoryType.expense,
        color: '#E8637C',
        iconType: IconType.system,
        iconValue: 'category_kitchen',
      ),
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
    onTap: () {},
    onReset: () {},
  );
}
