import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/section_label.dart';
import '../widgets/openmoji_icon.dart';

class SettingItem {
  const SettingItem(this.icon, this.label, this.onTap);
  final String icon;
  final String label;
  final VoidCallback onTap;
}

class SettingGroup {
  const SettingGroup(this.title, this.items);
  final String title;
  final List<SettingItem> items;
}

/// Pure Pengaturan layout: profile card, dark-mode toggle, and grouped
/// settings. All data/callbacks come from the [SettingsScreen] container —
/// this widget never reads [FinanceRepository], [Navigator], or
/// [ScaffoldMessenger] itself.
class SettingsView extends StatelessWidget {
  const SettingsView({
    super.key,
    required this.isDark,
    required this.settingGroups,
    required this.onToggleDarkMode,
    required this.onTapEditProfile,
    required this.onTapGenerateDummyData,
    required this.onTapClearAllData,
    required this.onTapLogout,
  });

  final bool isDark;
  final List<SettingGroup> settingGroups;
  final ValueChanged<bool> onToggleDarkMode;
  final VoidCallback onTapEditProfile;
  final VoidCallback onTapGenerateDummyData;
  final VoidCallback onTapClearAllData;
  final VoidCallback onTapLogout;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.accentHeaderOverlay,
      child: Scaffold(
        backgroundColor: palette.screenBg,
        body: SafeArea(
          top: false,
          bottom: false,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 22, 20, 26),
                color: AppColors.accent,
                child: Text('Pengaturan ⚙️', style: AppTheme.heading(fontSize: 21, color: Colors.white)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Transform.translate(
                  offset: const Offset(0, -24),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: palette.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 73,
                              height: 73,
                              decoration: const BoxDecoration(color: Color(0xFFFCE0E1), shape: BoxShape.circle),
                              alignment: Alignment.center,
                              child: const OpenMojiIcon(AppIcons.profileAvatar, size: 34),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Bunda Sari', style: AppTheme.heading(fontSize: 15, color: palette.textPrimary)),
                                  Text(
                                    'sari@keluarga.id',
                                    style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: palette.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Material(
                              color: palette.warningBg,
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: onTapEditProfile,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Text(
                                    'Edit',
                                    style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: palette.warningText),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: Material(
                            color: AppColors.accent.withValues(alpha: isDark ? 0.24 : 0.12),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: onTapGenerateDummyData,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 11),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const OpenMojiIcon(AppIcons.magic, size: 24),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Generate Data Dummy',
                                      style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.accent),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel('Tampilan', palette),
                    Container(
                      decoration: BoxDecoration(
                        color: palette.cardBg,
                        border: Border.all(color: palette.border),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                        child: MergeSemantics(
                          child: Row(
                            children: [
                              const OpenMojiIcon(AppIcons.darkMode, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Mode Gelap',
                                  style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: palette.textPrimary),
                                ),
                              ),
                              Switch(
                                value: isDark,
                                activeThumbColor: Colors.white,
                                activeTrackColor: AppColors.accent,
                                onChanged: onToggleDarkMode,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    for (final group in settingGroups) ...[
                      const SizedBox(height: 18),
                      SectionLabel(group.title, palette),
                      Container(
                        decoration: BoxDecoration(
                          color: palette.cardBg,
                          border: Border.all(color: palette.border),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < group.items.length; i++)
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: group.items[i].onTap,
                                  borderRadius: BorderRadius.vertical(
                                    top: i == 0 ? const Radius.circular(16) : Radius.zero,
                                    bottom: i == group.items.length - 1 ? const Radius.circular(16) : Radius.zero,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                    decoration: BoxDecoration(
                                      border: i < group.items.length - 1 ? Border(bottom: BorderSide(color: palette.border)) : null,
                                    ),
                                    child: Row(
                                      children: [
                                        OpenMojiIcon(group.items[i].icon, size: 31),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            group.items[i].label,
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
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: onTapClearAllData,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: palette.warningText),
                            ),
                            child: Text(
                              'Hapus Semua Data',
                              textAlign: TextAlign.center,
                              style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: palette.warningText),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: Material(
                        color: palette.warningBg,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: onTapLogout,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            child: Text(
                              'Keluar',
                              textAlign: TextAlign.center,
                              style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: palette.warningText),
                            ),
                          ),
                        ),
                      ),
                    ),
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

@Preview(name: 'SettingsView')
Widget previewSettingsView() {
  return SettingsView(
    isDark: false,
    settingGroups: [
      SettingGroup('Akun', [SettingItem(AppIcons.profile, 'Profil', () {}), SettingItem(AppIcons.security, 'Keamanan', () {})]),
      SettingGroup('Preferensi', [SettingItem(AppIcons.categoryBudgetSetting, 'Kategori & Anggaran', () {})]),
    ],
    onToggleDarkMode: (_) {},
    onTapEditProfile: () {},
    onTapGenerateDummyData: () {},
    onTapClearAllData: () {},
    onTapLogout: () {},
  );
}
