import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';

import '../models/category.dart' as models;
import '../models/icon_type.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/category_row.dart';
import '../widgets/empty_state.dart';
import '../widgets/segment_button.dart';

/// Pure Kelola Kategori layout: header, Pengeluaran/Pemasukan tab, the
/// category list (tap-to-edit), and an "add category" action. All
/// data/callbacks come from the [CategoryScreen] container — this widget
/// never reads [FinanceRepository] or [Navigator] itself.
class CategoryView extends StatelessWidget {
  const CategoryView({
    super.key,
    required this.tab,
    required this.categories,
    required this.onSelectTab,
    required this.onTapRow,
    required this.onTapAdd,
    required this.onTapBack,
  });

  final models.CategoryType tab;
  final List<models.Category> categories;
  final ValueChanged<models.CategoryType> onSelectTab;
  final ValueChanged<models.Category> onTapRow;
  final VoidCallback onTapAdd;
  final VoidCallback onTapBack;

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
                    Text('Kategori 🏷️', style: AppTheme.heading(fontSize: 18, color: Colors.white)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(color: palette.chipNeutral, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Expanded(
                            child: SegmentButton(
                              label: 'Pengeluaran',
                              selected: tab == models.CategoryType.expense,
                              color: AppColors.accent,
                              onTap: () => onSelectTab(models.CategoryType.expense),
                            ),
                          ),
                          Expanded(
                            child: SegmentButton(
                              label: 'Pemasukan',
                              selected: tab == models.CategoryType.income,
                              color: AppColors.accent,
                              onTap: () => onSelectTab(models.CategoryType.income),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (categories.isEmpty)
                      EmptyState(
                        palette: palette,
                        icon: AppIcons.categoryBudgetSetting,
                        iconSize: 44,
                        bordered: false,
                        title: 'Belum ada kategori di sini, Bun',
                      )
                    else
                      for (final category in categories)
                        CategoryRow(category: category, palette: palette, onTap: () => onTapRow(category)),
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
                              '+ Tambah Kategori',
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

@Preview(name: 'CategoryView · pengeluaran')
Widget previewCategoryViewExpense() {
  return CategoryView(
    tab: models.CategoryType.expense,
    categories: [
      const models.Category(
        id: 'preview-kitchen',
        name: 'Belanja Dapur',
        type: models.CategoryType.expense,
        color: '#FBD8B5',
        iconType: IconType.system,
        iconValue: 'category_kitchen',
      ),
      const models.Category(
        id: 'preview-snack',
        name: 'Jajan Anak',
        type: models.CategoryType.expense,
        color: '#F7C6D9',
        iconType: IconType.system,
        iconValue: 'category_kids_snack',
      ),
    ],
    onSelectTab: (_) {},
    onTapRow: (_) {},
    onTapAdd: () {},
    onTapBack: () {},
  );
}

@Preview(name: 'CategoryView · kosong')
Widget previewCategoryViewEmpty() {
  return CategoryView(
    tab: models.CategoryType.income,
    categories: const [],
    onSelectTab: (_) {},
    onTapRow: (_) {},
    onTapAdd: () {},
    onTapBack: () {},
  );
}
