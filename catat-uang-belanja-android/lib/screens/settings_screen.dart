import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../repositories/finance_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'budget_screen.dart';

class _SettingItem {
  const _SettingItem(this.icon, this.label, this.onTap);
  final String icon;
  final String label;
  final VoidCallback onTap;
}

class _SettingGroup {
  const _SettingGroup(this.title, this.items);
  final String title;
  final List<_SettingItem> items;
}

/// Pengaturan tab: profile card, dark-mode toggle wired to
/// [FinanceRepository.toggleDarkMode], and grouped settings. Only "Kategori
/// & Anggaran" and "Tentang Aplikasi" are live — the rest are "Segera hadir"
/// stubs, matching the mockup's scope exactly.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _openBudgetScreen(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const BudgetScreen()));
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Segera hadir ✨'),
        duration: Duration(milliseconds: 1200),
      ),
    );
  }

  Future<void> _generateDummyData(
    BuildContext context,
    FinanceRepository repository,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Generate Data Dummy?',
          style: AppTheme.heading(fontSize: 18),
        ),
        content: Text(
          'Ini akan menambahkan contoh dompet, anggaran, dan ±3 bulan transaksi ala ibu rumah tangga (gaji, belanja dapur, jajan anak, tagihan, dll) supaya tampilan aplikasi gampang dicoba.',
          style: AppTheme.body(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ya, Isi'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await repository.generateDummyData();
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data dummy berhasil ditambahkan ✨'),
        duration: Duration(milliseconds: 1500),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tentang Aplikasi', style: AppTheme.heading(fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Catat Uang Belanja',
              style: AppTheme.body(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Bantu Bunda mencatat belanja rumah tangga sehari-hari.',
              style: AppTheme.body(fontSize: 13),
            ),
            const SizedBox(height: 16),
            Text(
              'Ikon dalam aplikasi ini menggunakan Twemoji, © Twitter, Inc dan '
              'kontributor, dengan lisensi Creative Commons Attribution 4.0 (CC-BY 4.0).',
              style: AppTheme.body(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<FinanceRepository>();
    final palette = AppPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final settingGroups = [
      _SettingGroup('Akun', [
        _SettingItem(
          AppIcons.profile,
          'Profil',
          () => _showComingSoon(context),
        ),
        _SettingItem(
          AppIcons.security,
          'Keamanan',
          () => _showComingSoon(context),
        ),
      ]),
      _SettingGroup('Preferensi', [
        _SettingItem(
          AppIcons.notification,
          'Notifikasi',
          () => _showComingSoon(context),
        ),
        _SettingItem(
          AppIcons.categoryBudgetSetting,
          'Kategori & Anggaran',
          () => _openBudgetScreen(context),
        ),
        _SettingItem(
          AppIcons.language,
          'Bahasa',
          () => _showComingSoon(context),
        ),
      ]),
      _SettingGroup('Lainnya', [
        _SettingItem(AppIcons.help, 'Bantuan', () => _showComingSoon(context)),
        _SettingItem(
          AppIcons.about,
          'Tentang Aplikasi',
          () => _showAbout(context),
        ),
      ]),
    ];

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
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.of(context).padding.top + 22,
                  20,
                  26,
                ),
                color: AppColors.accent,
                child: Text(
                  'Pengaturan ⚙️',
                  style: AppTheme.heading(fontSize: 21, color: Colors.white),
                ),
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
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.35 : 0.10,
                          ),
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
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFCE0E1),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const TwemojiIcon(
                                AppIcons.profileAvatar,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bunda Sari',
                                    style: AppTheme.heading(
                                      fontSize: 15,
                                      color: palette.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'sari@keluarga.id',
                                    style: AppTheme.body(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: palette.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Material(
                              color: palette.warningBg,
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () => _showComingSoon(context),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Text(
                                    'Edit',
                                    style: AppTheme.body(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: palette.warningText,
                                    ),
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
                            color: AppColors.accent.withValues(
                              alpha: isDark ? 0.24 : 0.12,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () =>
                                  _generateDummyData(context, repository),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const TwemojiIcon(AppIcons.magic, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Generate Data Dummy',
                                      style: AppTheme.body(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.accent,
                                      ),
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
                    _SectionLabel('Tampilan', palette),
                    Container(
                      decoration: BoxDecoration(
                        color: palette.cardBg,
                        border: Border.all(color: palette.border),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        child: Row(
                          children: [
                            const TwemojiIcon(AppIcons.darkMode, size: 18),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Mode Gelap',
                                style: AppTheme.body(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: palette.textPrimary,
                                ),
                              ),
                            ),
                            Switch(
                              value: isDark,
                              activeThumbColor: Colors.white,
                              activeTrackColor: AppColors.accent,
                              onChanged: (_) => repository.toggleDarkMode(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    for (final group in settingGroups) ...[
                      const SizedBox(height: 18),
                      _SectionLabel(group.title, palette),
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
                                    top: i == 0
                                        ? const Radius.circular(16)
                                        : Radius.zero,
                                    bottom: i == group.items.length - 1
                                        ? const Radius.circular(16)
                                        : Radius.zero,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 13,
                                    ),
                                    decoration: BoxDecoration(
                                      border: i < group.items.length - 1
                                          ? Border(
                                              bottom: BorderSide(
                                                color: palette.border,
                                              ),
                                            )
                                          : null,
                                    ),
                                    child: Row(
                                      children: [
                                        TwemojiIcon(
                                          group.items[i].icon,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            group.items[i].label,
                                            style: AppTheme.body(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: palette.textPrimary,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '›',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: palette.borderStrong,
                                          ),
                                        ),
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
                        color: palette.warningBg,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _showComingSoon(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            child: Text(
                              'Keluar',
                              textAlign: TextAlign.center,
                              style: AppTheme.body(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: palette.warningText,
                              ),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, this.palette);
  final String text;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: AppTheme.body(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: palette.textSecondary,
        ),
      ),
    );
  }
}
