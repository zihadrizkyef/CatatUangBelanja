import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_theme.dart';

/// Uppercase section heading above a settings group card (e.g. "TAMPILAN").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, this.palette, {super.key});

  final String text;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: palette.textSecondary),
      ),
    );
  }
}

@Preview(name: 'SectionLabel')
Widget previewSectionLabel() {
  return SectionLabel('Tampilan', AppPalette.light);
}
