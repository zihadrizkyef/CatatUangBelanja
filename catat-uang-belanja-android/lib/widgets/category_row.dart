import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../models/category.dart' as models;
import '../models/icon_type.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'openmoji_icon.dart';

/// A single row in the Kelola Kategori list: icon, name, and a chevron that
/// opens the edit sheet on tap.
class CategoryRow extends StatelessWidget {
  const CategoryRow({super.key, required this.category, required this.palette, required this.onTap});

  final models.Category category;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconAsset = AppIcons.byIconValue[category.iconValue];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: palette.cardBg,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                if (iconAsset != null) OpenMojiIcon(iconAsset, size: 45),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    category.name,
                    style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: palette.textPrimary),
                  ),
                ),
                Text('›', style: TextStyle(fontSize: 14, color: palette.borderStrong)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

@Preview(name: 'CategoryRow')
Widget previewCategoryRow() {
  return CategoryRow(
    category: const models.Category(
      id: 'preview-category',
      name: 'Belanja Dapur',
      type: models.CategoryType.expense,
      color: '#FBD8B5',
      iconType: IconType.system,
      iconValue: 'category_kitchen',
    ),
    palette: AppPalette.light,
    onTap: () {},
  );
}
