import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:intl/intl.dart';

import '../models/category.dart' as models;
import '../models/icon_type.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/category_chip.dart';
import '../widgets/numeric_keypad.dart';
import '../widgets/twemoji_icon.dart';

/// Pure layout for [BudgetSheet]'s add/edit bottom sheet: category grid (add
/// mode) or a fixed category display (edit mode), plus the amount keypad and
/// an optional delete action. All data/callbacks come from the [BudgetSheet]
/// container — this widget never reads [FinanceRepository] or [Navigator]
/// itself.
class BudgetSheetView extends StatelessWidget {
  const BudgetSheetView({
    super.key,
    required this.isEdit,
    required this.categoryOptions,
    required this.selectedCategory,
    required this.amountStr,
    required this.onSelectCategory,
    required this.onKeyTap,
    required this.onClose,
    this.onDelete,
  });

  final bool isEdit;
  final List<models.Category> categoryOptions;
  final models.Category? selectedCategory;
  final String amountStr;
  final ValueChanged<models.Category> onSelectCategory;
  final ValueChanged<String> onKeyTap;
  final VoidCallback onClose;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(18, 18, 18, 22 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'Edit Anggaran' : 'Tambah Anggaran',
                  style: AppTheme.heading(fontSize: 17, color: palette.textPrimary),
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
                      child: Icon(Icons.close, size: 20, color: palette.textPrimary),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (!isEdit)
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
            else if (selectedCategory != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(color: palette.chipNeutral, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    if (AppIcons.byIconValue[selectedCategory!.iconValue] != null)
                      TwemojiIcon(AppIcons.byIconValue[selectedCategory!.iconValue]!, size: 32),
                    const SizedBox(width: 10),
                    Text(
                      selectedCategory!.name,
                      style: AppTheme.body(fontSize: 14, fontWeight: FontWeight.bold, color: palette.textPrimary),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Batas anggaran bulanan',
              textAlign: TextAlign.center,
              style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: palette.textSecondary),
            ),
            const SizedBox(height: 4),
            Text(
              'Rp ${amountStr.isEmpty ? '0' : NumberFormat('#,###', 'id_ID').format(int.parse(amountStr))}',
              textAlign: TextAlign.center,
              style: AppTheme.heading(fontSize: 30, color: palette.textPrimary),
            ),
            const SizedBox(height: 14),
            NumericKeypad(confirmColor: AppColors.gold, palette: palette, onKeyTap: onKeyTap),
            if (onDelete != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onDelete,
                child: Text(
                  'Hapus Anggaran Ini',
                  style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.accent),
                ),
              ),
            ],
          ],
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

@Preview(name: 'BudgetSheetView · tambah')
Widget previewBudgetSheetViewAdd() {
  return BudgetSheetView(
    isEdit: false,
    categoryOptions: [_previewCategory],
    selectedCategory: null,
    amountStr: '500000',
    onSelectCategory: (_) {},
    onKeyTap: (_) {},
    onClose: () {},
  );
}

@Preview(name: 'BudgetSheetView · edit')
Widget previewBudgetSheetViewEdit() {
  return BudgetSheetView(
    isEdit: true,
    categoryOptions: const [],
    selectedCategory: _previewCategory,
    amountStr: '1000000',
    onSelectCategory: (_) {},
    onKeyTap: (_) {},
    onClose: () {},
    onDelete: () {},
  );
}
