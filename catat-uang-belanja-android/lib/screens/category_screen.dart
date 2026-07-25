import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart' as models;
import '../repositories/finance_repository.dart';
import 'category_sheet.dart';
import 'category_view.dart';

/// Kelola Kategori CRUD screen — pushed via [Navigator] from Pengaturan's
/// "Kelola Kategori" row. Reads [FinanceRepository] and wires up the
/// add/edit [CategorySheet]; hands the rest to [CategoryView].
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, this.autoOpenAdd = false});

  /// When true, opens the "add category" sheet as soon as the screen
  /// appears — used by Anggaran's "Buat Kategori Dulu"/"Tambah Kategori
  /// Baru" prompts so the user lands straight in the add flow instead of an
  /// empty list they'd have to tap "+" on themselves.
  final bool autoOpenAdd;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  models.CategoryType _tab = models.CategoryType.expense;

  @override
  void initState() {
    super.initState();
    if (widget.autoOpenAdd) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _openSheet();
      });
    }
  }

  void _openSheet({models.Category? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategorySheet(type: _tab, existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<FinanceRepository>();
    final categoriesInTab = repository.categories.where((c) => c.type == _tab).toList();

    return CategoryView(
      tab: _tab,
      categories: categoriesInTab,
      onSelectTab: (tab) => setState(() => _tab = tab),
      onTapRow: (category) => _openSheet(existing: category),
      onTapAdd: () => _openSheet(),
      onTapBack: () => Navigator.of(context).pop(),
    );
  }
}
