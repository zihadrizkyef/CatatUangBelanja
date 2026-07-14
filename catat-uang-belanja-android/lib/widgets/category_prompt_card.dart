import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Chip-neutral prompt card shown in [BudgetSheetView]'s category picker
/// when no expense category is selectable — either because every category
/// already has a budget, or because none exist yet. [message] carries its
/// own leading emoji (matching the mockup's inline glyph, not an
/// [OpenMojiIcon]) since it's decorative text, not a lookup icon.
class CategoryPromptCard extends StatelessWidget {
  const CategoryPromptCard({
    super.key,
    required this.palette,
    required this.message,
    required this.buttonLabel,
    required this.onButtonTap,
  });

  final AppPalette palette;
  final String message;
  final String buttonLabel;
  final VoidCallback onButtonTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 14),
      decoration: BoxDecoration(color: palette.chipNeutral, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: palette.textSecondary),
          ),
          const SizedBox(height: 12),
          Material(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onButtonTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                child: Text(
                  buttonLabel,
                  style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

@Preview(name: 'CategoryPromptCard · semua sudah dianggarkan')
Widget previewCategoryPromptCardAllBudgeted() {
  return CategoryPromptCard(
    palette: AppPalette.light,
    message: '🎉 Semua kategori pengeluaran sudah punya anggaran',
    buttonLabel: '+ Tambah Kategori Baru',
    onButtonTap: () {},
  );
}

@Preview(name: 'CategoryPromptCard · belum ada kategori')
Widget previewCategoryPromptCardNoCategories() {
  return CategoryPromptCard(
    palette: AppPalette.light,
    message: '😅 Kamu belum punya kategori pengeluaran',
    buttonLabel: '+ Buat Kategori Dulu',
    onButtonTap: () {},
  );
}
