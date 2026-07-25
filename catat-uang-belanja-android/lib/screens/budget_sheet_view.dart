import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:intl/intl.dart';

import '../models/budget.dart';
import '../models/category.dart' as models;
import '../models/icon_type.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../utils/sheet_padding.dart';
import '../widgets/category_chip.dart';
import '../widgets/category_prompt_card.dart';
import '../widgets/numeric_keypad.dart';
import '../widgets/openmoji_icon.dart';
import '../widgets/option_chip.dart';
import '../widgets/segment_button.dart';

const _weekdayShortLabels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

String _periodLabel(BudgetPeriod period) => switch (period) {
  BudgetPeriod.monthly => 'Bulanan',
  BudgetPeriod.weekly => 'Mingguan',
  BudgetPeriod.event => 'Event',
};

/// Pure layout for [BudgetSheet]'s add/edit bottom sheet: category grid (add
/// mode) or a fixed category display (edit mode), the reset-period picker
/// (Bulanan/Mingguan/Event with its matching anchor picker), the amount
/// keypad, and — in edit mode — manual reset + delete actions. All
/// data/callbacks come from the [BudgetSheet] container — this widget never
/// touches [FinanceRepository] or [Navigator] itself.
class BudgetSheetView extends StatelessWidget {
  const BudgetSheetView({
    super.key,
    required this.isEdit,
    required this.categoryOptions,
    required this.hasExpenseCategories,
    required this.selectedCategory,
    required this.period,
    required this.monthDay,
    required this.weekday,
    required this.eventCategoryOptions,
    required this.selectedEventCategoryId,
    required this.amountStr,
    required this.onSelectCategory,
    required this.onCreateCategory,
    required this.onSelectPeriod,
    required this.onSelectMonthDay,
    required this.onSelectWeekday,
    required this.onSelectEventCategory,
    required this.onKeyTap,
    required this.onClose,
    this.onReset,
    this.onDelete,
  });

  final bool isEdit;
  final List<models.Category> categoryOptions;

  /// Whether the household has any expense category at all — distinguishes
  /// the "buat kategori dulu" empty state from "semua sudah dianggarkan"
  /// when [categoryOptions] is empty.
  final bool hasExpenseCategories;
  final models.Category? selectedCategory;
  final BudgetPeriod period;
  final int monthDay;
  final int weekday;
  final List<models.Category> eventCategoryOptions;
  final String? selectedEventCategoryId;
  final String amountStr;
  final ValueChanged<models.Category> onSelectCategory;
  final VoidCallback onCreateCategory;
  final ValueChanged<BudgetPeriod> onSelectPeriod;
  final ValueChanged<int> onSelectMonthDay;
  final ValueChanged<int> onSelectWeekday;
  final ValueChanged<models.Category> onSelectEventCategory;
  final ValueChanged<String> onKeyTap;
  final VoidCallback onClose;
  final VoidCallback? onReset;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(18, 18, 18, sheetBottomPadding(context)),
      // Explicit scrollbar thumb (see PM-06) — this sheet's content is often
      // taller than the screen (category grid + period picker + anchor
      // picker + keypad), with no other hint that it scrolls.
      child: Scrollbar(
        thumbVisibility: true,
        radius: const Radius.circular(8),
        thickness: 3,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'Edit Anggaran' : 'Tambah Anggaran',
                    style: AppTheme.heading(
                      fontSize: 17,
                      color: palette.textPrimary,
                    ),
                  ),
                  Material(
                    color: palette.warningBg,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onClose,
                      child: SizedBox(
                        width: 38,
                        height: 38,
                        child: Icon(
                          Icons.close,
                          size: 20,
                          color: palette.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (!isEdit)
                if (categoryOptions.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final cat in categoryOptions)
                        CategoryChip(
                          category: cat,
                          selected: selectedCategory?.id == cat.id,
                          selectedColor: AppColors.gold,
                          palette: palette,
                          onTap: () => onSelectCategory(cat),
                        ),
                    ],
                  )
                else
                  CategoryPromptCard(
                    palette: palette,
                    message: hasExpenseCategories
                        ? '🎉 Semua kategori pengeluaran sudah punya anggaran'
                        : '😅 Kamu belum punya kategori pengeluaran',
                    buttonLabel: hasExpenseCategories
                        ? '+ Tambah Kategori Baru'
                        : '+ Buat Kategori Dulu',
                    onButtonTap: onCreateCategory,
                  )
              else if (selectedCategory != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: palette.chipNeutral,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      if (AppIcons.byIconValue[selectedCategory!.iconValue] !=
                          null)
                        OpenMojiIcon(
                          AppIcons.byIconValue[selectedCategory!.iconValue]!,
                          size: 54,
                        ),
                      const SizedBox(width: 10),
                      Text(
                        selectedCategory!.name,
                        style: AppTheme.body(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: palette.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Periode reset anggaran',
                style: AppTheme.body(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: palette.chipNeutral,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    for (final opt in BudgetPeriod.values)
                      Expanded(
                        child: SegmentButton(
                          label: _periodLabel(opt),
                          selected: period == opt,
                          color: AppColors.accent,
                          onTap: () => onSelectPeriod(opt),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (period == BudgetPeriod.monthly) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Reset setiap tanggal berapa?',
                    style: AppTheme.body(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 34,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: 31,
                    separatorBuilder: (_, _) => const SizedBox(width: 6),
                    itemBuilder: (_, i) => OptionChip(
                      label: '${i + 1}',
                      selected: monthDay == i + 1,
                      onTap: () => onSelectMonthDay(i + 1),
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ] else if (period == BudgetPeriod.weekly) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Reset setiap hari apa?',
                    style: AppTheme.body(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (var i = 0; i < _weekdayShortLabels.length; i++)
                      OptionChip(
                        label: _weekdayShortLabels[i],
                        selected: weekday == i + 1,
                        onTap: () => onSelectWeekday(i + 1),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ] else ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Reset saat ada pemasukan dari kategori:',
                    style: AppTheme.body(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final cat in eventCategoryOptions)
                      CategoryChip(
                        category: cat,
                        selected: selectedEventCategoryId == cat.id,
                        selectedColor: AppColors.accent,
                        palette: palette,
                        onTap: () => onSelectEventCategory(cat),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              Text(
                'Batas anggaran per periode',
                textAlign: TextAlign.center,
                style: AppTheme.body(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Rp ${amountStr.isEmpty ? '0' : NumberFormat('#,###', 'id_ID').format(int.parse(amountStr))}',
                textAlign: TextAlign.center,
                style: AppTheme.heading(
                  fontSize: 30,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              NumericKeypad(
                confirmColor: AppColors.gold,
                palette: palette,
                onKeyTap: onKeyTap,
              ),
              if (isEdit) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: palette.chipNeutral,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: onReset,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            child: Text(
                              '↻ Reset Sekarang',
                              textAlign: TextAlign.center,
                              style: AppTheme.body(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: palette.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: onDelete,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.accent),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Hapus Anggaran',
                              textAlign: TextAlign.center,
                              style: AppTheme.body(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

final _previewCategory = const models.Category(
  id: 'preview-category',
  name: 'Dapur',
  type: models.CategoryType.expense,
  color: '#E8637C',
  iconType: IconType.system,
  iconValue: 'category_kitchen',
);

final _previewIncomeCategory = const models.Category(
  id: 'preview-income-category',
  name: 'Gaji',
  type: models.CategoryType.income,
  color: '#C4EBD9',
  iconType: IconType.system,
  iconValue: 'category_salary',
);

@Preview(name: 'BudgetSheetView · tambah')
Widget previewBudgetSheetViewAdd() {
  return BudgetSheetView(
    isEdit: false,
    categoryOptions: [_previewCategory],
    hasExpenseCategories: true,
    selectedCategory: null,
    period: BudgetPeriod.monthly,
    monthDay: 1,
    weekday: DateTime.monday,
    eventCategoryOptions: [_previewIncomeCategory],
    selectedEventCategoryId: null,
    amountStr: '500000',
    onSelectCategory: (_) {},
    onCreateCategory: () {},
    onSelectPeriod: (_) {},
    onSelectMonthDay: (_) {},
    onSelectWeekday: (_) {},
    onSelectEventCategory: (_) {},
    onKeyTap: (_) {},
    onClose: () {},
  );
}

@Preview(name: 'BudgetSheetView · tambah (semua sudah dianggarkan)')
Widget previewBudgetSheetViewAddAllBudgeted() {
  return BudgetSheetView(
    isEdit: false,
    categoryOptions: const [],
    hasExpenseCategories: true,
    selectedCategory: null,
    period: BudgetPeriod.monthly,
    monthDay: 1,
    weekday: DateTime.monday,
    eventCategoryOptions: [_previewIncomeCategory],
    selectedEventCategoryId: null,
    amountStr: '',
    onSelectCategory: (_) {},
    onCreateCategory: () {},
    onSelectPeriod: (_) {},
    onSelectMonthDay: (_) {},
    onSelectWeekday: (_) {},
    onSelectEventCategory: (_) {},
    onKeyTap: (_) {},
    onClose: () {},
  );
}

@Preview(name: 'BudgetSheetView · tambah (belum ada kategori)')
Widget previewBudgetSheetViewAddNoCategories() {
  return BudgetSheetView(
    isEdit: false,
    categoryOptions: const [],
    hasExpenseCategories: false,
    selectedCategory: null,
    period: BudgetPeriod.monthly,
    monthDay: 1,
    weekday: DateTime.monday,
    eventCategoryOptions: [_previewIncomeCategory],
    selectedEventCategoryId: null,
    amountStr: '',
    onSelectCategory: (_) {},
    onCreateCategory: () {},
    onSelectPeriod: (_) {},
    onSelectMonthDay: (_) {},
    onSelectWeekday: (_) {},
    onSelectEventCategory: (_) {},
    onKeyTap: (_) {},
    onClose: () {},
  );
}

@Preview(name: 'BudgetSheetView · edit (event)')
Widget previewBudgetSheetViewEdit() {
  return BudgetSheetView(
    isEdit: true,
    categoryOptions: const [],
    hasExpenseCategories: true,
    selectedCategory: _previewCategory,
    period: BudgetPeriod.event,
    monthDay: 1,
    weekday: DateTime.monday,
    eventCategoryOptions: [_previewIncomeCategory],
    selectedEventCategoryId: _previewIncomeCategory.id,
    amountStr: '1000000',
    onSelectCategory: (_) {},
    onCreateCategory: () {},
    onSelectPeriod: (_) {},
    onSelectMonthDay: (_) {},
    onSelectWeekday: (_) {},
    onSelectEventCategory: (_) {},
    onKeyTap: (_) {},
    onClose: () {},
    onReset: () {},
    onDelete: () {},
  );
}
