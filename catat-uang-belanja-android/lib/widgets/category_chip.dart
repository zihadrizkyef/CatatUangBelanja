import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../models/category.dart' as models;
import '../models/icon_type.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'openmoji_icon.dart';

/// Selectable category tile used by the amount-entry sheets (transaction and
/// budget). [selectedColor] is the accent used for the border/highlight when
/// [selected] is true — expense/income sheets pass a type-dependent accent,
/// the budget sheet always passes [AppColors.gold].
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.category,
    required this.selected,
    required this.selectedColor,
    required this.palette,
    required this.onTap,
  });

  final models.Category category;
  final bool selected;
  final Color selectedColor;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconAsset = AppIcons.byIconValue[category.iconValue];
    return Material(
      color: selected ? palette.screenBg : palette.cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 92,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? selectedColor : palette.border,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              if (iconAsset != null) OpenMojiIcon(iconAsset, size: 36),
              const SizedBox(height: 4),
              Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: AppTheme.body(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
        ),
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

@Preview(name: 'CategoryChip · selected')
Widget previewCategoryChipSelected() {
  return CategoryChip(
    category: _previewCategory,
    selected: true,
    selectedColor: AppColors.peach,
    palette: AppPalette.light,
    onTap: () {},
  );
}

@Preview(name: 'CategoryChip · unselected')
Widget previewCategoryChipUnselected() {
  return CategoryChip(
    category: _previewCategory,
    selected: false,
    selectedColor: AppColors.peach,
    palette: AppPalette.light,
    onTap: () {},
  );
}
