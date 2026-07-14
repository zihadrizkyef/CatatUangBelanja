import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart' as models;
import '../models/icon_type.dart';
import '../repositories/finance_repository.dart';
import '../theme/app_icons.dart';
import 'category_sheet_view.dart';

/// Add/edit bottom sheet container for a single category: name field + the
/// icon-grid picker. New categories are created with [type] (the tab the
/// sheet was opened from); editing never changes a category's type. Reads
/// [FinanceRepository] and wires up the sheet's [Navigator] dismissal; hands
/// the rest to [CategorySheetView].
class CategorySheet extends StatefulWidget {
  const CategorySheet({super.key, required this.type, this.existing});

  final models.CategoryType type;
  final models.Category? existing;

  @override
  State<CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<CategorySheet> {
  late final TextEditingController _nameController;
  late String _iconValue;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _iconValue = widget.existing?.iconValue ?? AppIcons.categoryIconChoices.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final repository = context.read<FinanceRepository>();
    final color = AppIcons.categoryIconColors[_iconValue] ?? '#F3ECE6';
    if (_isEdit) {
      await repository.updateCategory(widget.existing!.copyWith(name: name, iconValue: _iconValue, color: color));
    } else {
      await repository.addCategory(models.Category(
        id: const Uuid().v4(),
        name: name,
        type: widget.type,
        color: color,
        iconType: IconType.system,
        iconValue: _iconValue,
      ));
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final repository = context.read<FinanceRepository>();
    if (repository.budgets.any((b) => b.categoryId == existing.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kategori ini masih dipakai di anggaran. Hapus anggarannya dulu, Bun.'),
          duration: Duration(milliseconds: 2000),
        ),
      );
      return;
    }
    await repository.deleteCategory(existing.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    return CategorySheetView(
      isEdit: _isEdit,
      canDelete: existing != null && !existing.isSystem,
      nameController: _nameController,
      selectedIconValue: _iconValue,
      onSelectIcon: (value) => setState(() => _iconValue = value),
      onSave: _save,
      onClose: () => Navigator.of(context).pop(),
      onDelete: _isEdit ? _delete : null,
    );
  }
}
