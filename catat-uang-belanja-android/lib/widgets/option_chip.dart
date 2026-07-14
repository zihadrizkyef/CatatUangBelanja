import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Small selectable bordered pill used for plain-label option pickers (e.g.
/// the budget sheet's reset-day-of-month and reset-weekday choices). Pass
/// [size] for a fixed square (day-of-month grid); omit it for an
/// auto-width pill (weekday chips).
class OptionChip extends StatelessWidget {
  const OptionChip({super.key, required this.label, required this.selected, required this.onTap, this.size});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Material(
      color: selected ? palette.screenBg : palette.cardBg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          padding: size == null ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8) : null,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? AppColors.accent : palette.border, width: 2),
          ),
          child: Text(label, style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: palette.textPrimary)),
        ),
      ),
    );
  }
}

@Preview(name: 'OptionChip · square selected')
Widget previewOptionChipSquareSelected() {
  return OptionChip(label: '1', selected: true, onTap: () {}, size: 34);
}

@Preview(name: 'OptionChip · pill unselected')
Widget previewOptionChipPillUnselected() {
  return OptionChip(label: 'Senin', selected: false, onTap: () {});
}
