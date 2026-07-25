import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../utils/sheet_padding.dart';
import '../widgets/icon_choice_tile.dart';
import '../widgets/openmoji_icon.dart';

/// Pure layout for [CategorySheet]'s add/edit bottom sheet: name field,
/// icon-picker grid, a save action, and — in edit mode, for non-system
/// categories only — a delete action. All data/callbacks come from the
/// [CategorySheet] container — this widget never touches [FinanceRepository]
/// or [Navigator] itself.
class CategorySheetView extends StatelessWidget {
  const CategorySheetView({
    super.key,
    required this.isEdit,
    required this.canDelete,
    required this.nameController,
    required this.selectedIconValue,
    required this.onSelectIcon,
    required this.onSave,
    required this.onClose,
    this.onDelete,
  });

  final bool isEdit;
  final bool canDelete;
  final TextEditingController nameController;
  final String selectedIconValue;
  final ValueChanged<String> onSelectIcon;
  final VoidCallback onSave;
  final VoidCallback onClose;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final selectedIconAsset = AppIcons.byIconValue[selectedIconValue];

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(18, 18, 18, sheetBottomPadding(context)),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'Edit Kategori' : 'Tambah Kategori',
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
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: palette.chipNeutral, borderRadius: BorderRadius.circular(16)),
                  alignment: Alignment.center,
                  child: selectedIconAsset != null ? OpenMojiIcon(selectedIconAsset, size: 48) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: nameController,
                    style: AppTheme.body(fontSize: 14, fontWeight: FontWeight.bold, color: palette.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Nama kategori',
                      hintStyle: AppTheme.body(fontSize: 14, fontWeight: FontWeight.bold, color: palette.textSecondary),
                      filled: true,
                      fillColor: palette.chipNeutral,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: palette.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: palette.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.accent, width: 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Pilih ikon', style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: palette.textSecondary)),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                for (final iconValue in AppIcons.categoryIconChoices)
                  if (AppIcons.byIconValue[iconValue] case final asset?)
                    IconChoiceTile(
                      iconAsset: asset,
                      selected: selectedIconValue == iconValue,
                      onTap: () => onSelectIcon(iconValue),
                    ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onSave,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      'Simpan',
                      textAlign: TextAlign.center,
                      style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            if (isEdit && canDelete) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.accent),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Hapus Kategori',
                        textAlign: TextAlign.center,
                        style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

@Preview(name: 'CategorySheetView · tambah')
Widget previewCategorySheetViewAdd() {
  return CategorySheetView(
    isEdit: false,
    canDelete: false,
    nameController: TextEditingController(),
    selectedIconValue: 'category_kitchen',
    onSelectIcon: (_) {},
    onSave: () {},
    onClose: () {},
  );
}

@Preview(name: 'CategorySheetView · edit')
Widget previewCategorySheetViewEdit() {
  return CategorySheetView(
    isEdit: true,
    canDelete: true,
    nameController: TextEditingController(text: 'Belanja Dapur'),
    selectedIconValue: 'category_kitchen',
    onSelectIcon: (_) {},
    onSave: () {},
    onClose: () {},
    onDelete: () {},
  );
}

@Preview(name: 'CategorySheetView · edit (kategori bawaan)')
Widget previewCategorySheetViewEditSystem() {
  return CategorySheetView(
    isEdit: true,
    canDelete: false,
    nameController: TextEditingController(text: 'Gaji'),
    selectedIconValue: 'category_salary',
    onSelectIcon: (_) {},
    onSave: () {},
    onClose: () {},
  );
}
