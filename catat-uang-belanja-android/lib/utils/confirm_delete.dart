import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shared "yakin mau hapus?" dialog for destructive deletes across sheets
/// (Transaksi/Dompet/Kategori/Anggaran) — none of these asked for
/// confirmation before, so a single mistap (easy to make right above the
/// numeric keypad) deleted data instantly with no way to undo from the UI.
Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title, style: AppTheme.heading(fontSize: 18)),
      content: Text(message, style: AppTheme.body(fontSize: 13)),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
        TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Ya, Hapus')),
      ],
    ),
  );
  return confirmed ?? false;
}
