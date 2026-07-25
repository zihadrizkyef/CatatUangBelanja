import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'filter_option.dart';
import 'openmoji_icon.dart';

/// One selectable row inside a [FilterDropdownPanel]'s option list.
class FilterOptionRow extends StatelessWidget {
  const FilterOptionRow({super.key, required this.option, required this.palette});

  final FilterOption option;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: option.selected ? palette.chipNeutral : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: option.onSelect,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            children: [
              if (option.iconAsset != null) ...[OpenMojiIcon(option.iconAsset!, size: 24), const SizedBox(width: 8)],
              Expanded(
                child: Text(
                  option.label,
                  style: AppTheme.body(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: option.selected ? AppColors.accent : palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@Preview(name: 'FilterOptionRow · selected')
Widget previewFilterOptionRowSelected() {
  return FilterOptionRow(
    option: (id: 'k1', label: 'Belanja Dapur', iconAsset: 'assets/icons/openmoji/shopping_trolley.svg', selected: true, onSelect: () {}),
    palette: AppPalette.light,
  );
}

@Preview(name: 'FilterOptionRow · unselected')
Widget previewFilterOptionRowUnselected() {
  return FilterOptionRow(
    option: (id: '', label: 'Semua Kategori', iconAsset: null, selected: false, onSelect: () {}),
    palette: AppPalette.light,
  );
}
