import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PengaturanScreen extends StatelessWidget {
  const PengaturanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Pengaturan', style: AppTheme.heading(fontSize: 24)),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.palette_rounded),
            title: Text('Tema & Background', style: AppTheme.body()),
          ),
          ListTile(
            leading: const Icon(Icons.lock_rounded),
            title: Text('Kunci Aplikasi', style: AppTheme.body()),
          ),
          ListTile(
            leading: const Icon(Icons.backup_rounded),
            title: Text('Backup & Restore', style: AppTheme.body()),
          ),
          ListTile(
            leading: const Icon(Icons.category_rounded),
            title: Text('Kategori & Anggaran', style: AppTheme.body()),
          ),
          ListTile(
            leading: const Icon(Icons.repeat_rounded),
            title: Text('Transaksi Berulang', style: AppTheme.body()),
          ),
        ],
      ),
    );
  }
}
