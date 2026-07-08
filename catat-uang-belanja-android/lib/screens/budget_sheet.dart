import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/budget.dart';
import '../models/budget_status.dart';
import '../models/category.dart' as models;
import '../repositories/finance_repository.dart';
import 'budget_sheet_view.dart';

/// Add/edit bottom sheet container: category grid (add mode only — the
/// category is fixed once a budget exists) + numeric keypad for the monthly
/// limit. Reads/writes [FinanceRepository] and wires the sheet's [Navigator]
/// dismissal; hands the rest to [BudgetSheetView].
class BudgetSheet extends StatefulWidget {
  const BudgetSheet({super.key, this.existing});

  final BudgetStatus? existing;

  @override
  State<BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends State<BudgetSheet> {
  models.Category? _category;
  String _amountStr = '';

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      _category = widget.existing!.category;
      _amountStr = widget.existing!.budget.limitAmount.toString();
    }
  }

  void _pressKey(String k) {
    if (k == '✓') {
      _save();
      return;
    }
    setState(() {
      if (k == '⌫') {
        _amountStr = _amountStr.isEmpty ? '' : _amountStr.substring(0, _amountStr.length - 1);
      } else if (_amountStr.length < 9) {
        _amountStr += k;
      }
    });
  }

  Future<void> _save() async {
    final amount = int.tryParse(_amountStr);
    if (amount == null || amount <= 0 || _category == null) return;
    final repository = context.read<FinanceRepository>();
    final now = DateTime.now();
    final budget = _isEdit
        ? widget.existing!.budget.copyWith(limitAmount: amount, updatedAt: now)
        : Budget(id: const Uuid().v4(), categoryId: _category!.id, limitAmount: amount, createdAt: now, updatedAt: now);
    await repository.setBudget(budget);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    if (widget.existing == null) return;
    await context.read<FinanceRepository>().deleteBudget(widget.existing!.budget.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<FinanceRepository>();
    final budgetedIds = repository.budgets.map((b) => b.categoryId).toSet();
    final categoryOptions = repository.categories
        .where((c) => c.type == models.CategoryType.expense && !budgetedIds.contains(c.id))
        .toList();

    return BudgetSheetView(
      isEdit: _isEdit,
      categoryOptions: categoryOptions,
      selectedCategory: _category,
      amountStr: _amountStr,
      onSelectCategory: (cat) => setState(() => _category = cat),
      onKeyTap: _pressKey,
      onClose: () => Navigator.of(context).pop(),
      onDelete: _isEdit ? _delete : null,
    );
  }
}
