import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:intl/intl.dart';

import '../models/budget.dart';
import '../models/budget_status.dart';
import '../models/category.dart';
import '../models/icon_type.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'openmoji_icon.dart';

final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

/// Beranda's "near/over limit" budget callout — shown when the top-ranked
/// [BudgetStatus.pct] is at or above 80%.
class WarningBudgetBanner extends StatelessWidget {
  const WarningBudgetBanner({super.key, required this.status, required this.palette});

  final BudgetStatus status;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final clampedPct = status.pct.clamp(0, 100);
    final isOverLimit = status.pct >= 100;
    final message = isOverLimit
        ? '${status.category.name} udah lewat batas nih, Bun — yuk cek lagi ya 💛'
        : '${status.category.name} udah mendekati batas nih, Bun — yuk dipantau terus ya 💛';
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: palette.warningBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: palette.cardShadow, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 59,
                height: 59,
                decoration: BoxDecoration(color: palette.cardBg, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: OpenMojiIcon(AppIcons.byIconValue[status.category.iconValue] ?? AppIcons.budgetTarget, size: 48),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(status.category.name, style: AppTheme.body(fontSize: 14, fontWeight: FontWeight.bold, color: palette.textPrimary)),
                    Text(
                      '${_currency.format(status.used)} dari ${_currency.format(status.budget.limitAmount)}',
                      style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: palette.textSecondary),
                    ),
                  ],
                ),
              ),
              Text('$clampedPct%', style: AppTheme.heading(fontSize: 15, color: palette.warningText)),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              message,
              style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: palette.warningText),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: clampedPct / 100,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}

final _previewStatus = BudgetStatus(
  category: const Category(
    id: 'preview-category',
    name: 'Dapur',
    type: CategoryType.expense,
    color: '#E8637C',
    iconType: IconType.system,
    iconValue: 'category_kitchen',
  ),
  budget: Budget(id: 'preview-budget', categoryId: 'preview-category', limitAmount: 1000000, createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1)),
  used: 850000,
  pct: 85,
);

@Preview(name: 'WarningBudgetBanner · mendekati batas')
Widget previewWarningBudgetBanner() {
  return WarningBudgetBanner(status: _previewStatus, palette: AppPalette.light);
}

final _previewOverLimitStatus = BudgetStatus(
  category: const Category(
    id: 'preview-category-2',
    name: 'Hiburan Keluarga',
    type: CategoryType.expense,
    color: '#9B8FBD',
    iconType: IconType.system,
    iconValue: 'category_entertainment',
  ),
  budget: Budget(id: 'preview-budget-2', categoryId: 'preview-category-2', limitAmount: 200000, createdAt: DateTime(2026, 1, 1), updatedAt: DateTime(2026, 1, 1)),
  used: 235000,
  pct: 118,
);

@Preview(name: 'WarningBudgetBanner · lewat batas')
Widget previewWarningBudgetBannerOverLimit() {
  return WarningBudgetBanner(status: _previewOverLimitStatus, palette: AppPalette.light);
}
