import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'filter_option.dart';
import 'filter_option_row.dart';

/// The expanded search+options panel a [FilterDropdown] shows below its
/// button when open.
class FilterDropdownPanel extends StatelessWidget {
  const FilterDropdownPanel({
    super.key,
    required this.searchController,
    required this.searchHint,
    required this.options,
    required this.noMatchesText,
    required this.palette,
  });

  final TextEditingController searchController;
  final String searchHint;
  final List<FilterOption> options;
  final String noMatchesText;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      constraints: const BoxConstraints(maxHeight: 260),
      decoration: BoxDecoration(color: palette.cardBg, border: Border.all(color: palette.border), borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: searchController,
            autofocus: true,
            style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: palette.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: palette.chipNeutral,
              hintText: searchHint,
              hintStyle: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: palette.textSecondary),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: palette.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: palette.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.accent, width: 2)),
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: options.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(noMatchesText, textAlign: TextAlign.center, style: AppTheme.body(fontSize: 12, color: palette.textSecondary)),
                  )
                : ListView(
                    shrinkWrap: true,
                    children: [for (final o in options) FilterOptionRow(option: o, palette: palette)],
                  ),
          ),
        ],
      ),
    );
  }
}

@Preview(name: 'FilterDropdownPanel')
Widget previewFilterDropdownPanel() {
  return FilterDropdownPanel(
    searchController: TextEditingController(),
    searchHint: 'Cari kategori…',
    options: [
      (id: '', label: 'Semua Kategori', iconAsset: null, selected: false, onSelect: () {}),
      (id: 'k1', label: 'Belanja Dapur', iconAsset: 'assets/icons/openmoji/shopping_trolley.svg', selected: true, onSelect: () {}),
    ],
    noMatchesText: 'Kategori tidak ditemukan',
    palette: AppPalette.light,
  );
}
