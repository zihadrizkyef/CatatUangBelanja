import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../utils/sheet_padding.dart';
import '../widgets/icon_choice_tile.dart';
import '../widgets/openmoji_icon.dart';

/// Pure layout for [ProfileEditSheet]: name field + avatar-picker grid. All
/// data/callbacks come from the [ProfileEditSheet] container — this widget
/// never touches [FinanceRepository] or [Navigator] itself.
class ProfileEditSheetView extends StatelessWidget {
  const ProfileEditSheetView({
    super.key,
    required this.nameController,
    required this.selectedAvatarIconValue,
    required this.onSelectAvatar,
    required this.onSave,
    required this.onClose,
  });

  final TextEditingController nameController;
  final String selectedAvatarIconValue;
  final ValueChanged<String> onSelectAvatar;
  final VoidCallback onSave;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

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
                Text('Edit Profil', style: AppTheme.heading(fontSize: 17, color: palette.textPrimary)),
                Material(
                  color: palette.warningBg,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onClose,
                    child: SizedBox(width: 38, height: 38, child: Icon(Icons.close, size: 20, color: palette.textPrimary)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 73,
                height: 73,
                decoration: const BoxDecoration(color: Color(0xFFFCE0E1), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: OpenMojiIcon(selectedAvatarIconValue, size: 34),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              style: AppTheme.body(fontSize: 14, fontWeight: FontWeight.bold, color: palette.textPrimary),
              decoration: InputDecoration(
                hintText: 'Nama kamu',
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
            const SizedBox(height: 20),
            Text('Pilih avatar', style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: palette.textSecondary)),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                for (final iconAsset in AppIcons.avatarIconChoices)
                  IconChoiceTile(
                    iconAsset: iconAsset,
                    selected: selectedAvatarIconValue == iconAsset,
                    onTap: () => onSelectAvatar(iconAsset),
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
          ],
        ),
      ),
    );
  }
}

@Preview(name: 'ProfileEditSheetView')
Widget previewProfileEditSheetView() {
  return ProfileEditSheetView(
    nameController: TextEditingController(text: 'Bunda Sari'),
    selectedAvatarIconValue: AppIcons.profileAvatar,
    onSelectAvatar: (_) {},
    onSave: () {},
    onClose: () {},
  );
}
