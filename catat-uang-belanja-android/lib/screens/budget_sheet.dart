import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/budget.dart';
import '../models/budget_status.dart';
import '../models/category.dart' as models;
import '../repositories/finance_repository.dart';
import '../utils/confirm_delete.dart';
import '../utils/snackbar.dart';
import 'budget_sheet_view.dart';
import 'category_screen.dart';

/// Add/edit bottom sheet container: category grid (add mode only — the
/// category is fixed once a budget exists), the reset-period picker
/// (Bulanan/Mingguan/Event and its anchor), and the numeric keypad for the
/// per-period limit. Reads/writes [FinanceRepository] and wires up the
/// sheet's [Navigator] dismissal; hands the rest to [BudgetSheetView].
class BudgetSheet extends StatefulWidget {
  const BudgetSheet({super.key, this.existing});

  final BudgetStatus? existing;

  @override
  State<BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends State<BudgetSheet> {
  models.Category? _category;
  String _amountStr = '';
  BudgetPeriod _period = BudgetPeriod.monthly;
  int _monthDay = 1;
  int _weekday = DateTime.monday;
  String? _eventCategoryId;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing?.budget;
    if (existing != null) {
      _category = widget.existing!.category;
      _amountStr = existing.limitAmount.toString();
      _period = existing.period;
      switch (existing.period) {
        case BudgetPeriod.monthly:
          _monthDay = existing.resetAnchor ?? 1;
        case BudgetPeriod.weekly:
          _weekday = existing.resetAnchor ?? DateTime.monday;
        case BudgetPeriod.event:
          _eventCategoryId = existing.triggerCategoryId;
      }
    } else {
      final repository = context.read<FinanceRepository>();
      final budgetedIds = repository.budgets.map((b) => b.categoryId).toSet();
      final categoryOptions = repository.categories
          .where((c) => c.type == models.CategoryType.expense && !budgetedIds.contains(c.id));
      _category = categoryOptions.firstOrNull;
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
    if (amount == null || amount <= 0) {
      showSnackBarMessage(context, 'Isi batas anggarannya dulu ya, Bun');
      return;
    }
    if (_category == null) {
      showSnackBarMessage(context, 'Pilih kategorinya dulu ya, Bun');
      return;
    }
    if (_period == BudgetPeriod.event && _eventCategoryId == null) {
      showSnackBarMessage(context, 'Pilih kategori pemasukan pemicunya dulu ya, Bun');
      return;
    }

    final repository = context.read<FinanceRepository>();
    final now = DateTime.now();
    final resetAnchor = switch (_period) {
      BudgetPeriod.monthly => _monthDay,
      BudgetPeriod.weekly => _weekday,
      BudgetPeriod.event => null,
    };
    final triggerCategoryId = _period == BudgetPeriod.event ? _eventCategoryId : null;

    final budget = Budget(
      id: _isEdit ? widget.existing!.budget.id : const Uuid().v4(),
      categoryId: _category!.id,
      period: _period,
      resetAnchor: resetAnchor,
      triggerCategoryId: triggerCategoryId,
      limitAmount: amount,
      currentPeriodStartedAt: _isEdit
          ? widget.existing!.budget.currentPeriodStartedAt
          : repository.periodStartFor(period: _period, resetAnchor: resetAnchor, now: now),
      createdAt: _isEdit ? widget.existing!.budget.createdAt : now,
      updatedAt: now,
    );
    await repository.setBudget(budget);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final confirmed = await confirmDelete(
      context,
      title: 'Hapus Anggaran?',
      message: 'Anggaran "${existing.category.name}" akan dihapus dan tidak bisa dikembalikan, Bun.',
    );
    if (!confirmed || !mounted) return;
    await context.read<FinanceRepository>().deleteBudget(existing.budget.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _resetNow() async {
    if (widget.existing == null) return;
    await context.read<FinanceRepository>().resetBudgetNow(widget.existing!.budget.id);
    if (mounted) Navigator.of(context).pop();
  }

  void _goCreateCategory() {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(MaterialPageRoute(builder: (_) => const CategoryScreen(autoOpenAdd: true)));
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<FinanceRepository>();
    final budgetedIds = repository.budgets.map((b) => b.categoryId).toSet();
    final expenseCategories = repository.categories.where((c) => c.type == models.CategoryType.expense);
    final categoryOptions = expenseCategories.where((c) => !budgetedIds.contains(c.id)).toList();
    final eventCategoryOptions = repository.categories.where((c) => c.type == models.CategoryType.income).toList();

    return BudgetSheetView(
      isEdit: _isEdit,
      categoryOptions: categoryOptions,
      hasExpenseCategories: expenseCategories.isNotEmpty,
      selectedCategory: _category,
      period: _period,
      monthDay: _monthDay,
      weekday: _weekday,
      eventCategoryOptions: eventCategoryOptions,
      selectedEventCategoryId: _eventCategoryId,
      amountStr: _amountStr,
      onSelectCategory: (cat) => setState(() => _category = cat),
      onCreateCategory: _goCreateCategory,
      onSelectPeriod: (period) => setState(() => _period = period),
      onSelectMonthDay: (day) => setState(() => _monthDay = day),
      onSelectWeekday: (weekday) => setState(() => _weekday = weekday),
      onSelectEventCategory: (cat) => setState(() => _eventCategoryId = cat.id),
      onKeyTap: _pressKey,
      onClose: () => Navigator.of(context).pop(),
      onReset: _isEdit ? _resetNow : null,
      onDelete: _isEdit ? _delete : null,
    );
  }
}
