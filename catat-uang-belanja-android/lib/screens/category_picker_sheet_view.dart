import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../models/category.dart' as models;
import '../models/icon_type.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../utils/sheet_padding.dart';
import '../widgets/category_chip.dart';
import '../widgets/empty_state.dart';

/// Pure layout for [CategoryPickerSheet]: a search field plus a scrollable
/// wrap of [CategoryChip]s. Never touches [Navigator] itself — taps report
/// back via [onSelectCategory]/[onClose].
class CategoryPickerSheetView extends StatelessWidget {
  const CategoryPickerSheetView({
    super.key,
    required this.searchController,
    required this.query,
    required this.categories,
    required this.selectedCategory,
    required this.accentColor,
    required this.onQueryChanged,
    required this.onSelectCategory,
    required this.onClose,
  });

  final TextEditingController searchController;
  final String query;
  final List<models.Category> categories;
  final models.Category? selectedCategory;
  final Color accentColor;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<models.Category> onSelectCategory;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(18, 18, 18, sheetBottomPadding(context)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pilih Kategori',
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
          TextField(
            controller: searchController,
            onChanged: onQueryChanged,
            style: AppTheme.body(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: palette.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Cari kategori...',
              hintStyle: AppTheme.body(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: palette.textSecondary,
              ),
              prefixIcon: Icon(Icons.search, size: 20, color: palette.textSecondary),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      icon: Icon(Icons.clear, size: 18, color: palette.textSecondary),
                      onPressed: () {
                        searchController.clear();
                        onQueryChanged('');
                      },
                    ),
              filled: true,
              fillColor: palette.chipNeutral,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Flexible(
            child: categories.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: EmptyState(
                      palette: palette,
                      icon: AppIcons.emptyReceipt,
                      bordered: false,
                      title: 'Kategori "$query" tidak ketemu, Bun.',
                    ),
                  )
                : SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final cat in categories)
                          CategoryChip(
                            category: cat,
                            selected: selectedCategory?.id == cat.id,
                            selectedColor: accentColor,
                            palette: palette,
                            onTap: () => onSelectCategory(cat),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

final _previewPickerCategories = const [
  models.Category(
    id: 'preview-category-kitchen',
    name: 'Belanja Dapur',
    type: models.CategoryType.expense,
    color: '#FBD8B5',
    iconType: IconType.system,
    iconValue: 'category_kitchen',
  ),
  models.Category(
    id: 'preview-category-kids-snack',
    name: 'Jajan Anak',
    type: models.CategoryType.expense,
    color: '#F7C6D9',
    iconType: IconType.system,
    iconValue: 'category_kids_snack',
  ),
  models.Category(
    id: 'preview-category-school',
    name: 'Sekolah Anak',
    type: models.CategoryType.expense,
    color: '#DCD3F0',
    iconType: IconType.system,
    iconValue: 'category_school',
  ),
  models.Category(
    id: 'preview-category-arisan',
    name: 'Arisan',
    type: models.CategoryType.expense,
    color: '#C4EBD9',
    iconType: IconType.system,
    iconValue: 'category_arisan',
  ),
];

@Preview(name: 'CategoryPickerSheetView · hasil')
Widget previewCategoryPickerSheetViewResults() {
  return CategoryPickerSheetView(
    searchController: TextEditingController(),
    query: '',
    categories: _previewPickerCategories,
    selectedCategory: _previewPickerCategories.first,
    accentColor: AppColors.peach,
    onQueryChanged: (_) {},
    onSelectCategory: (_) {},
    onClose: () {},
  );
}

@Preview(name: 'CategoryPickerSheetView · tidak ketemu')
Widget previewCategoryPickerSheetViewEmpty() {
  return CategoryPickerSheetView(
    searchController: TextEditingController(text: 'zzz'),
    query: 'zzz',
    categories: const [],
    selectedCategory: null,
    accentColor: AppColors.peach,
    onQueryChanged: (_) {},
    onSelectCategory: (_) {},
    onClose: () {},
  );
}
