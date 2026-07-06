import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

const _keypadKeys = [
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
  '⌫',
  '0',
  '✓',
];

/// 3x4 numeric keypad ('⌫' to backspace, '✓' to confirm) shared by the
/// transaction and budget amount-entry sheets. [confirmColor] highlights the
/// '✓' key — type-dependent accent for transactions, [AppColors.gold] for
/// budgets.
class NumericKeypad extends StatelessWidget {
  const NumericKeypad({
    super.key,
    required this.confirmColor,
    required this.palette,
    required this.onKeyTap,
  });

  final Color confirmColor;
  final AppPalette palette;
  final ValueChanged<String> onKeyTap;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.7,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final k in _keypadKeys)
          Material(
            color: k == '✓'
                ? confirmColor
                : (k == '⌫' ? palette.chipNeutral : palette.chipKey),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onKeyTap(k),
              child: Center(
                child: Text(
                  k,
                  style: AppTheme.heading(
                    fontSize: 18,
                    color: k == '✓' ? Colors.white : palette.textPrimary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

@Preview(name: 'NumericKeypad')
Widget previewNumericKeypad() {
  return NumericKeypad(
    confirmColor: AppColors.peach,
    palette: AppPalette.light,
    onKeyTap: (_) {},
  );
}
