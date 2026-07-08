import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// One half of the expense/income segmented toggle atop [TransactionSheet].
class SegmentButton extends StatelessWidget {
  const SegmentButton({super.key, required this.label, required this.selected, required this.color, required this.onTap});

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.body(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: selected ? Colors.white : AppPalette.of(context).textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

@Preview(name: 'SegmentButton · selected')
Widget previewSegmentButtonSelected() {
  return SegmentButton(label: 'Pengeluaran', selected: true, color: AppColors.peach, onTap: () {});
}

@Preview(name: 'SegmentButton · unselected')
Widget previewSegmentButtonUnselected() {
  return SegmentButton(label: 'Pemasukan', selected: false, color: AppColors.gold, onTap: () {});
}
