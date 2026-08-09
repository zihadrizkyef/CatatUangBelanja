import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../repositories/finance_repository.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'budget_screen.dart';
import 'category_screen.dart';
import 'jago_settings_screen.dart';
import 'login_screen.dart';
import 'profile_edit_sheet.dart';
import 'security_settings_screen.dart';
import 'settings_view.dart';

/// Pengaturan tab container: profile card, dark-mode toggle wired to
/// [FinanceRepository.toggleDarkMode], and grouped settings. "Kelola
/// Kategori", "Anggaran", "Tentang Aplikasi", "Profil"/"Edit Profil",
/// "Keamanan", and "Keluar" are live; "Notifikasi"/"Bantuan" are still
/// "Segera hadir" stubs. Reads [FinanceRepository] and wires up
/// [Navigator]/sheet/dialog/toast actions; hands the rest to [SettingsView].
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _openCategoryScreen() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CategoryScreen()));
  }

  void _openBudgetScreen() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BudgetScreen()));
  }

  void _openSecuritySettings() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SecuritySettingsScreen()));
  }

  void _openJagoSettings() {
    if (!context.read<FinanceRepository>().isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masuk dengan Google dulu sebelum menghubungkan Bank Jago, Bun.')),
      );
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const JagoSettingsScreen()));
  }

  void _openLogin() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _openProfileEdit() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProfileEditSheet(),
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Segera hadir ✨'), duration: Duration(milliseconds: 1200)),
    );
  }

  Future<void> _generateDummyData() async {
    final repository = context.read<FinanceRepository>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Generate Data Dummy?', style: AppTheme.heading(fontSize: 18)),
        content: Text(
          'Ini akan menambahkan contoh dompet, anggaran, dan ±3 bulan transaksi ala ibu rumah tangga (gaji, belanja dapur, jajan anak, tagihan, dll) supaya tampilan aplikasi gampang dicoba.',
          style: AppTheme.body(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Ya, Isi')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await repository.generateDummyData();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data dummy berhasil ditambahkan ✨'), duration: Duration(milliseconds: 1500)),
    );
  }

  Future<void> _clearAllData() async {
    final repository = context.read<FinanceRepository>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Semua Data?', style: AppTheme.heading(fontSize: 18)),
        content: Text(
          'Semua dompet, kategori, anggaran, dan transaksi yang sudah dicatat akan dihapus dan tidak bisa dikembalikan. Yakin mau lanjut, Bun?',
          style: AppTheme.body(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Ya, Hapus')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await repository.clearAllData();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Semua data berhasil dihapus'), duration: Duration(milliseconds: 1500)),
    );
  }

  Future<void> _logout() async {
    final repository = context.read<FinanceRepository>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Keluar Akun?', style: AppTheme.heading(fontSize: 18)),
        content: Text(
          'Data yang sudah tersimpan tetap ada di HP ini — kamu tinggal masuk lagi kapan saja, Bun.',
          style: AppTheme.body(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Ya, Keluar')),
        ],
      ),
    );
    if (confirmed != true) return;
    await repository.signOut();
  }

  void _showAbout() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tentang Aplikasi', style: AppTheme.heading(fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Catat Uang Belanja', style: AppTheme.body(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Bantu Bunda mencatat belanja rumah tangga sehari-hari.', style: AppTheme.body(fontSize: 13)),
            const SizedBox(height: 16),
            Text(
              'Ikon dalam aplikasi ini menggunakan OpenMoji, dengan lisensi Creative '
              'Commons Attribution-ShareAlike 4.0 (CC BY-SA 4.0).',
              style: AppTheme.body(fontSize: 12),
            ),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Tutup'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<FinanceRepository>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SettingsView(
      isDark: isDark,
      profileName: repository.profileName,
      profileAvatarIconValue: repository.profileAvatarIconValue,
      profileSubtitle: repository.userEmail ?? 'Belum masuk',
      isLoggedIn: repository.isLoggedIn,
      isSigningIn: false,
      settingGroups: [
        SettingGroup('Akun', [
          SettingItem(AppIcons.profile, 'Profil', _openProfileEdit),
          SettingItem(AppIcons.security, 'Keamanan', _openSecuritySettings),
          SettingItem(AppIcons.bankJago, 'Bank Jago', _openJagoSettings),
        ]),
        SettingGroup('Preferensi', [
          SettingItem(AppIcons.notification, 'Notifikasi', _showComingSoon),
          SettingItem(AppIcons.categoryBudgetSetting, 'Kelola Kategori', _openCategoryScreen),
          SettingItem(AppIcons.budgetTarget, 'Anggaran', _openBudgetScreen),
        ]),
        SettingGroup('Lainnya', [
          SettingItem(AppIcons.help, 'Bantuan', _showComingSoon),
          SettingItem(AppIcons.about, 'Tentang Aplikasi', _showAbout),
        ]),
      ],
      onToggleDarkMode: (_) => repository.toggleDarkMode(),
      onTapEditProfile: _openProfileEdit,
      onTapGenerateDummyData: _generateDummyData,
      onTapClearAllData: _clearAllData,
      onTapLogout: _logout,
      onTapLogin: _openLogin,
    );
  }
}
