import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'openmoji_icon.dart';

/// One square cell in [CategorySheetView]'s icon-picker grid.
class IconChoiceTile extends StatelessWidget {
  const IconChoiceTile({super.key, required this.iconAsset, required this.selected, required this.onTap});

  final String iconAsset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Material(
      color: selected ? palette.screenBg : palette.chipNeutral,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColors.accent : palette.border, width: 2),
          ),
          alignment: Alignment.center,
          child: OpenMojiIcon(iconAsset, size: 33),
        ),
      ),
    );
  }
}

@Preview(name: 'IconChoiceTile · selected')
Widget previewIconChoiceTileSelected() {
  return IconChoiceTile(iconAsset: 'assets/icons/openmoji/shopping_trolley.svg', selected: true, onTap: () {});
}

@Preview(name: 'IconChoiceTile · unselected')
Widget previewIconChoiceTileUnselected() {
  return IconChoiceTile(iconAsset: 'assets/icons/openmoji/lollipop.svg', selected: false, onTap: () {});
}
