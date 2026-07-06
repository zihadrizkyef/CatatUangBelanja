import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/budget.dart';
import '../models/budget_status.dart';
import '../models/category.dart' as models;
import '../repositories/finance_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/category_chip.dart';
import '../widgets/numeric_keypad.dart';

final _currency = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0,
);

/// Full-screen budget CRUD (was AnggaranScreen in the mockup) — pushed via
/// [Navigator] from the "Kelola" links on Beranda/Rangkuman and Pengaturan's
/// "Kategori & Anggaran" row. List of [BudgetStatus] with tap-to-edit, plus
/// an add/edit bottom sheet with a category grid and numeric keypad.
class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  void _openSheet(BuildContext context, {BudgetStatus? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BudgetSheet(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<FinanceRepository>();
    final palette = AppPalette.of(context);
    final budgetStatuses = repository.budgetStatuses;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.accentHeaderOverlay,
      child: Scaffold(
        backgroundColor: palette.screenBg,
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.of(context).padding.top + 18,
                  16,
                  20,
                ),
                color: AppColors.accent,
                child: Row(
                  children: [
                    Material(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.of(context).pop(),
                        child: const SizedBox(
                          width: 32,
                          height: 32,
                          child: Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Anggaran 🎯',
                      style: AppTheme.heading(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  children: [
                    if (budgetStatuses.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            const TwemojiIcon(
                              AppIcons.budgetSeedling,
                              size: 34,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Belum ada anggaran. Yuk buat yang pertama, Bun!',
                              textAlign: TextAlign.center,
                              style: AppTheme.body(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      for (final status in budgetStatuses)
                        _BudgetRow(
                          status: status,
                          palette: palette,
                          onTap: () => _openSheet(context, existing: status),
                        ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: Material(
                        color: palette.warningBg,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => _openSheet(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            child: Text(
                              '+ Tambah Anggaran',
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

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({
    required this.status,
    required this.palette,
    required this.onTap,
  });

  final BudgetStatus status;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final clampedPct = status.pct.clamp(0, 100);
    final barColor = status.pct >= 100
        ? AppColors.dangerBar
        : (status.pct >= 80 ? AppColors.warningBar : AppColors.okBar);
    final iconAsset = AppIcons.byIconValue[status.category.iconValue];

    return Material(
      color: palette.cardBg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            border: Border.all(color: palette.border),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (iconAsset != null) TwemojiIcon(iconAsset, size: 19),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      status.category.name,
                      style: AppTheme.body(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '›',
                    style: TextStyle(fontSize: 16, color: palette.borderStrong),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '${_currency.format(status.used)} dari ${_currency.format(status.budget.limitAmount)}',
                    style: AppTheme.body(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: palette.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${status.pct}%',
                    style: AppTheme.heading(fontSize: 13, color: barColor),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: clampedPct / 100,
                  minHeight: 6,
                  backgroundColor: palette.warningBg,
                  valueColor: AlwaysStoppedAnimation(barColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Add/edit bottom sheet: category grid (add mode only — the category is
/// fixed once a budget exists) + numeric keypad for the monthly limit.
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
        _amountStr = _amountStr.isEmpty
            ? ''
            : _amountStr.substring(0, _amountStr.length - 1);
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
        : Budget(
            id: const Uuid().v4(),
            categoryId: _category!.id,
            limitAmount: amount,
            createdAt: now,
            updatedAt: now,
          );
    await repository.setBudget(budget);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    if (widget.existing == null) return;
    await context.read<FinanceRepository>().deleteBudget(
      widget.existing!.budget.id,
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<FinanceRepository>();
    final palette = AppPalette.of(context);
    final budgetedIds = repository.budgets.map((b) => b.categoryId).toSet();
    final categoryOptions = repository.categories
        .where(
          (c) =>
              c.type == models.CategoryType.expense &&
              !budgetedIds.contains(c.id),
        )
        .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        18,
        18,
        18,
        22 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _isEdit ? 'Edit Anggaran' : 'Tambah Anggaran',
                  style: AppTheme.heading(
                    fontSize: 17,
                    color: palette.textPrimary,
                  ),
                ),
                Material(
                  color: palette.warningBg,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).pop(),
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: Icon(
                        Icons.close,
                        size: 15,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (!_isEdit)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final cat in categoryOptions)
                    CategoryChip(
                      category: cat,
                      selected: _category?.id == cat.id,
                      selectedColor: AppColors.gold,
                      palette: palette,
                      onTap: () => setState(() => _category = cat),
                    ),
                ],
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: palette.chipNeutral,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    if (AppIcons.byIconValue[_category!.iconValue] != null)
                      TwemojiIcon(
                        AppIcons.byIconValue[_category!.iconValue]!,
                        size: 20,
                      ),
                    const SizedBox(width: 10),
                    Text(
                      _category!.name,
                      style: AppTheme.body(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Text(
              'Batas anggaran bulanan',
              textAlign: TextAlign.center,
              style: AppTheme.body(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Rp ${_amountStr.isEmpty ? '0' : NumberFormat('#,###', 'id_ID').format(int.parse(_amountStr))}',
              textAlign: TextAlign.center,
              style: AppTheme.heading(fontSize: 30, color: palette.textPrimary),
            ),
            const SizedBox(height: 14),
            NumericKeypad(
              confirmColor: AppColors.gold,
              palette: palette,
              onKeyTap: _pressKey,
            ),
            if (_isEdit) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: _delete,
                child: Text(
                  'Hapus Anggaran Ini',
                  style: AppTheme.body(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
