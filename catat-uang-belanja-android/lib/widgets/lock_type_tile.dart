import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'openmoji_icon.dart';

/// One selectable row in [SecuritySettingsView]'s "Metode Kunci" list (PIN
/// vs biometric), with a trailing check/circle indicating selection.
class LockTypeTile extends StatelessWidget {
  const LockTypeTile({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.palette,
    this.subtitle,
  });

  final String icon;
  final String label;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? palette.warningBg : palette.cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: selected ? AppColors.accent : palette.border, width: selected ? 1.5 : 1),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              OpenMojiIcon(icon, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: palette.textPrimary)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: AppTheme.body(fontSize: 11, color: palette.textSecondary)),
                    ],
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? AppColors.accent : palette.borderStrong,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@Preview(name: 'LockTypeTile · terpilih')
Widget previewLockTypeTileSelected() {
  return LockTypeTile(icon: AppIcons.security, label: 'PIN 6 Digit', selected: true, onTap: () {}, palette: AppPalette.light);
}

@Preview(name: 'LockTypeTile · tidak tersedia')
Widget previewLockTypeTileUnavailable() {
  return LockTypeTile(
    icon: AppIcons.biometric,
    label: 'Sidik Jari / Face ID',
    subtitle: 'Belum tersedia di HP ini',
    selected: false,
    onTap: () {},
    palette: AppPalette.light,
  );
}
