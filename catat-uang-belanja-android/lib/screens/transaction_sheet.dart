import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart' as models;
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../repositories/finance_repository.dart';
import '../theme/app_theme.dart';

/// Opened from AppShell's "+" FAB (doc 6.2): pick Pemasukan/Pengeluaran,
/// nominal, dompet, kategori, catatan opsional, then save.
class TransactionSheet extends StatefulWidget {
  const TransactionSheet({super.key});

  @override
  State<TransactionSheet> createState() => _TransactionSheetState();
}

class _TransactionSheetState extends State<TransactionSheet> {
  TransactionType _type = TransactionType.expense;
  Wallet? _wallet;
  models.Category? _category;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  models.CategoryType get _categoryType =>
      _type == TransactionType.income ? models.CategoryType.income : models.CategoryType.expense;

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<FinanceRepository>();
    _wallet ??= repository.wallets.isNotEmpty ? repository.wallets.first : null;

    final categories = repository.categories.where((c) => c.type == _categoryType).toList();
    if (_category == null || _category!.type != _categoryType) {
      _category = categories.isNotEmpty ? categories.first : null;
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Catat Transaksi', style: AppTheme.heading(fontSize: 20)),
          const SizedBox(height: 16),
          SegmentedButton<TransactionType>(
            segments: const [
              ButtonSegment(value: TransactionType.expense, label: Text('Pengeluaran')),
              ButtonSegment(value: TransactionType.income, label: Text('Pemasukan')),
            ],
            selected: {_type},
            onSelectionChanged: (selection) => setState(() => _type = selection.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Nominal (Rp)'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Wallet>(
            key: ValueKey('wallet-${_wallet?.id}'),
            initialValue: _wallet,
            decoration: const InputDecoration(labelText: 'Dompet'),
            items: [
              for (final wallet in repository.wallets)
                DropdownMenuItem(value: wallet, child: Text(wallet.name)),
            ],
            onChanged: (wallet) => setState(() => _wallet = wallet),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<models.Category>(
            key: ValueKey('category-${_category?.id}'),
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Kategori'),
            items: [
              for (final category in categories)
                DropdownMenuItem(value: category, child: Text(category.name)),
            ],
            onChanged: (category) => setState(() => _category = category),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _wallet == null ? null : _save,
              child: const Text('Simpan'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final amount = int.tryParse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (amount == null || amount <= 0 || _wallet == null) return;

    final now = DateTime.now();
    final transaction = Transaction(
      id: const Uuid().v4(),
      type: _type,
      amount: amount,
      walletId: _wallet!.id,
      categoryId: _category?.id,
      dateTime: now,
      note: _noteController.text.isEmpty ? null : _noteController.text,
      createdAt: now,
      updatedAt: now,
    );

    await context.read<FinanceRepository>().addTransaction(transaction);
    if (mounted) Navigator.of(context).pop();
  }
}
