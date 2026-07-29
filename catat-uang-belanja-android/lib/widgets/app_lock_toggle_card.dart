import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'openmoji_icon.dart';

/// [SecuritySettingsView]'s app-lock master switch card.
class AppLockToggleCard extends StatelessWidget {
  const AppLockToggleCard({super.key, required this.enabled, required this.onToggle, required this.palette});

  final bool enabled;
  final ValueChanged<bool> onToggle;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: palette.cardBg,
        border: Border.all(color: palette.border),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: MergeSemantics(
        child: Row(
          children: [
            OpenMojiIcon(AppIcons.security, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kunci Aplikasi', style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: palette.textPrimary)),
                  const SizedBox(height: 2),
                  Text(
                    'Minta PIN/sidik jari setiap kali aplikasi dibuka',
                    style: AppTheme.body(fontSize: 11, color: palette.textSecondary),
                  ),
                ],
              ),
            ),
            Switch(value: enabled, activeThumbColor: Colors.white, activeTrackColor: AppColors.accent, onChanged: onToggle),
          ],
        ),
      ),
    );
  }
}

@Preview(name: 'AppLockToggleCard · aktif')
Widget previewAppLockToggleCardOn() {
  return AppLockToggleCard(enabled: true, onToggle: (_) {}, palette: AppPalette.light);
}

@Preview(name: 'AppLockToggleCard · nonaktif')
Widget previewAppLockToggleCardOff() {
  return AppLockToggleCard(enabled: false, onToggle: (_) {}, palette: AppPalette.light);
}
