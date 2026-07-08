import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart' as models;
import '../models/transaction.dart';
import '../repositories/finance_repository.dart';
import 'transaction_sheet_view.dart';

/// Opened from AppShell's "+" FAB (doc 6.2) container: expense/income
/// toggle, amount keypad, category grid, and a wallet chip that cycles
/// through wallets on tap — matches the mockup's `TransactionSheet.dc.html`.
/// Reads/writes [FinanceRepository]; hands the rest to
/// [TransactionSheetView].
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

  models.CategoryType get _categoryType =>
      _type == TransactionType.income ? models.CategoryType.income : models.CategoryType.expense;

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
        _amountStr = _amountStr.isEmpty ? '' : _amountStr.substring(0, _amountStr.length - 1);
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
    final wallets = repository.wallets;
    final wallet = wallets.isEmpty ? null : wallets[_walletIndex % wallets.length];
    final categories = repository.categories.where((c) => c.type == _categoryType).toList();

    return TransactionSheetView(
      isIncome: _type == TransactionType.income,
      amountStr: _amountStr,
      categories: categories,
      selectedCategory: _category,
      wallet: wallet,
      onSelectType: _setType,
      onSelectCategory: (cat) => setState(() => _category = cat),
      onTapWallet: () => _cycleWallet(wallets.length),
      onKeyTap: _pressKey,
      onClose: () => Navigator.of(context).pop(),
    );
  }
}
