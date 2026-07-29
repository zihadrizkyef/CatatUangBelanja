import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';

import '../models/app_lock_type.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/app_lock_toggle_card.dart';
import '../widgets/lock_type_tile.dart';
import '../widgets/section_label.dart';

/// Pure Keamanan layout: header, app-lock master toggle, PIN/biometric
/// method choice, and "Ubah PIN". All data/callbacks come from
/// [SecuritySettingsScreen] — this widget never reads [FinanceRepository] or
/// [Navigator] itself.
class SecuritySettingsView extends StatelessWidget {
  const SecuritySettingsView({
    super.key,
    required this.appLockEnabled,
    required this.appLockType,
    required this.biometricAvailable,
    required this.onToggleAppLock,
    required this.onSelectLockType,
    required this.onTapChangePin,
    required this.onTapBack,
  });

  final bool appLockEnabled;
  final AppLockType appLockType;
  final bool biometricAvailable;
  final ValueChanged<bool> onToggleAppLock;
  final ValueChanged<AppLockType> onSelectLockType;
  final VoidCallback onTapChangePin;
  final VoidCallback onTapBack;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.accentHeaderOverlay,
      child: Scaffold(
        backgroundColor: palette.screenBg,
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 18, 16, 20),
                color: AppColors.accent,
                child: Row(
                  children: [
                    Material(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onTapBack,
                        child: const SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(Icons.chevron_left, color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Keamanan 🔒', style: AppTheme.heading(fontSize: 18, color: Colors.white)),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  children: [
                    AppLockToggleCard(
                      enabled: appLockEnabled,
                      onToggle: onToggleAppLock,
                      palette: palette,
                    ),
                    if (appLockEnabled) ...[
                      const SizedBox(height: 18),
                      SectionLabel('Metode Kunci', palette),
                      LockTypeTile(
                        icon: AppIcons.security,
                        label: 'PIN 6 Digit',
                        selected: appLockType == AppLockType.pin,
                        onTap: () => onSelectLockType(AppLockType.pin),
                        palette: palette,
                      ),
                      const SizedBox(height: 8),
                      LockTypeTile(
                        icon: AppIcons.biometric,
                        label: 'Sidik Jari / Face ID',
                        subtitle: biometricAvailable ? null : 'Belum tersedia di HP ini',
                        selected: appLockType == AppLockType.biometric,
                        onTap: () => onSelectLockType(AppLockType.biometric),
                        palette: palette,
                      ),
                      const SizedBox(height: 18),
                      SectionLabel('Lainnya', palette),
                      Material(
                        color: palette.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: onTapChangePin,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: palette.border),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Ubah PIN',
                                    style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: palette.textPrimary),
                                  ),
                                ),
                                Text('›', style: TextStyle(fontSize: 16, color: palette.borderStrong)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@Preview(name: 'SecuritySettingsView · nonaktif')
Widget previewSecuritySettingsViewOff() {
  return SecuritySettingsView(
    appLockEnabled: false,
    appLockType: AppLockType.none,
    biometricAvailable: true,
    onToggleAppLock: (_) {},
    onSelectLockType: (_) {},
    onTapChangePin: () {},
    onTapBack: () {},
  );
}

@Preview(name: 'SecuritySettingsView · PIN aktif')
Widget previewSecuritySettingsViewPinActive() {
  return SecuritySettingsView(
    appLockEnabled: true,
    appLockType: AppLockType.pin,
    biometricAvailable: false,
    onToggleAppLock: (_) {},
    onSelectLockType: (_) {},
    onTapChangePin: () {},
    onTapBack: () {},
  );
}
