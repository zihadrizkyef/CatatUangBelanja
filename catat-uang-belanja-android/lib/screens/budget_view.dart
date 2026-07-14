import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';

import '../models/budget.dart';
import '../models/budget_status.dart';
import '../models/category.dart' as models;
import '../models/icon_type.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/budget_row.dart';
import '../widgets/empty_state.dart';

/// Pure Anggaran layout: header, the [BudgetStatus] list (tap-to-edit), and
/// an "add budget" action. All data/callbacks come from the [BudgetScreen]
/// container — this widget never reads [FinanceRepository] or [Navigator]
/// itself.
class BudgetView extends StatelessWidget {
  const BudgetView({
    super.key,
    required this.budgetStatuses,
    required this.onTapRow,
    required this.onTapAdd,
    required this.onTapBack,
    required this.onTapReset,
  });

  final List<BudgetStatus> budgetStatuses;
  final ValueChanged<BudgetStatus> onTapRow;
  final VoidCallback onTapAdd;
  final VoidCallback onTapBack;
  final ValueChanged<BudgetStatus> onTapReset;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.accentHeaderOverlay,
      child: Scaffold(
        backgroundColor: palette.screenBg,
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 18, 16, 20),
                color: AppColors.accent,
                child: Row(
                  children: [
                    Material(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onTapBack,
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(Icons.chevron_left, color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Anggaran 🎯', style: AppTheme.heading(fontSize: 18, color: Colors.white)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  children: [
                    if (budgetStatuses.isEmpty)
                      EmptyState(
                        palette: palette,
                        icon: AppIcons.budgetSeedling,
                        iconSize: 48,
                        bordered: false,
                        title: 'Belum ada anggaran. Yuk buat yang pertama, Bun!',
                      )
                    else
                      for (final status in budgetStatuses)
                        BudgetRow(
                          status: status,
                          palette: palette,
                          onTap: () => onTapRow(status),
                          onReset: () => onTapReset(status),
                        ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: Material(
                        color: palette.warningBg,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: onTapAdd,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            child: Text(
                              '+ Tambah Anggaran',
                              textAlign: TextAlign.center,
                              style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: palette.warningText),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@Preview(name: 'BudgetView')
Widget previewBudgetView() {
  return BudgetView(
    budgetStatuses: [
      BudgetStatus(
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
    ],
    onTapRow: (_) {},
    onTapAdd: () {},
    onTapBack: () {},
    onTapReset: (_) {},
  );
}

@Preview(name: 'BudgetView · kosong')
Widget previewBudgetViewEmpty() {
  return BudgetView(
    budgetStatuses: const [],
    onTapRow: (_) {},
    onTapAdd: () {},
    onTapBack: () {},
    onTapReset: (_) {},
  );
}
