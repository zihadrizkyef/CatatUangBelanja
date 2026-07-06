import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart' as models;
import '../models/transaction.dart';
import '../repositories/finance_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

const _keypadKeys = [
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
  '⌫',
  '0',
  '✓',
];

/// Opened from AppShell's "+" FAB (doc 6.2): expense/income toggle, amount
/// keypad, category grid, and a wallet chip that cycles through wallets on
/// tap — matches the mockup's `TransactionSheet.dc.html`.
class TransactionSheet extends StatefulWidget {
  const TransactionSheet({super.key});

  @override
  State<TransactionSheet> createState() => _TransactionSheetState();
}

class _TransactionSheetState extends State<TransactionSheet> {
  TransactionType _type = TransactionType.expense;
  int _walletIndex = 0;
  models.Category? _category;
  String _amountStr = '';

  models.CategoryType get _categoryType => _type == TransactionType.income
      ? models.CategoryType.income
      : models.CategoryType.expense;

  void _setType(TransactionType type) {
    setState(() {
      _type = type;
      _category = null;
    });
  }

  void _cycleWallet(int walletCount) {
    if (walletCount == 0) return;
    setState(() => _walletIndex = (_walletIndex + 1) % walletCount);
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
    final repository = context.read<FinanceRepository>();
    final wallets = repository.wallets;
    final amount = int.tryParse(_amountStr);
    if (amount == null || amount <= 0 || _category == null || wallets.isEmpty) {
      return;
    }

    final wallet = wallets[_walletIndex % wallets.length];
    final now = DateTime.now();
    final transaction = Transaction(
      id: const Uuid().v4(),
      type: _type,
      amount: amount,
      walletId: wallet.id,
      categoryId: _category!.id,
      dateTime: now,
      createdAt: now,
      updatedAt: now,
    );

    await repository.addTransaction(transaction);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<FinanceRepository>();
    final palette = AppPalette.of(context);
    final wallets = repository.wallets;
    final wallet = wallets.isEmpty
        ? null
        : wallets[_walletIndex % wallets.length];

    final categories = repository.categories
        .where((c) => c.type == _categoryType)
        .toList();
    final isIncome = _type == TransactionType.income;
    final accent = isIncome ? AppColors.gold : AppColors.peach;

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
                  isIncome ? 'Tambah Pemasukan' : 'Tambah Pengeluaran',
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
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: palette.chipNeutral,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _SegmentButton(
                      label: 'Pengeluaran',
                      selected: !isIncome,
                      color: AppColors.peach,
                      onTap: () => _setType(TransactionType.expense),
                    ),
                  ),
                  Expanded(
                    child: _SegmentButton(
                      label: 'Pemasukan',
                      selected: isIncome,
                      color: AppColors.gold,
                      onTap: () => _setType(TransactionType.income),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Rp ${_amountStr.isEmpty ? '0' : NumberFormat('#,###', 'id_ID').format(int.parse(_amountStr))}',
              textAlign: TextAlign.center,
              style: AppTheme.heading(fontSize: 30, color: palette.textPrimary),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cat in categories)
                  _CategoryChip(
                    category: cat,
                    selected: _category?.id == cat.id,
                    accent: accent,
                    palette: palette,
                    onTap: () => setState(() => _category = cat),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (wallet != null)
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: palette.chipNeutral,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _cycleWallet(wallets.length),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          if (AppIcons.byIconValue[wallet.iconValue] != null)
                            TwemojiIcon(
                              AppIcons.byIconValue[wallet.iconValue]!,
                              size: 16,
                            ),
                          const SizedBox(width: 8),
                          Text(
                            'Dompet: ${wallet.name}',
                            style: AppTheme.body(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: palette.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.7,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final k in _keypadKeys)
                  Material(
                    color: k == '✓'
                        ? accent
                        : (k == '⌫' ? palette.chipNeutral : palette.chipKey),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _pressKey(k),
                      child: Center(
                        child: Text(
                          k,
                          style: AppTheme.heading(
                            fontSize: 18,
                            color: k == '✓'
                                ? Colors.white
                                : palette.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTheme.body(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: selected
                  ? Colors.white
                  : AppPalette.of(context).textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.accent,
    required this.palette,
    required this.onTap,
  });

  final models.Category category;
  final bool selected;
  final Color accent;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconAsset = AppIcons.byIconValue[category.iconValue];
    return Material(
      color: selected ? palette.screenBg : palette.cardBg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 78,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? accent : palette.border,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              if (iconAsset != null) TwemojiIcon(iconAsset, size: 20),
              const SizedBox(height: 4),
              Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: AppTheme.body(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: palette.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
