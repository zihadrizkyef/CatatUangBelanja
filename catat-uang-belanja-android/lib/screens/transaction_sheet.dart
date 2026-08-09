import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/category.dart' as models;
import '../models/transaction.dart';
import '../repositories/finance_repository.dart';
import '../utils/confirm_delete.dart';
import '../utils/snackbar.dart';
import 'transaction_sheet_view.dart';

/// Opened from AppShell's "+" FAB (doc 6.2) container: expense/income
/// toggle, amount keypad, category grid, and a wallet chip that cycles
/// through wallets on tap — matches the mockup's `TransactionSheet.dc.html`.
/// Reads/writes [FinanceRepository]; hands the rest to
/// [TransactionSheetView].
class TransactionSheet extends StatefulWidget {
  const TransactionSheet({super.key, this.existing});

  /// When set, the sheet opens in edit mode: fields are prefilled from this
  /// transaction, saving calls [FinanceRepository.updateTransaction] instead
  /// of adding a new row, and a "Hapus Transaksi" action becomes available.
  final Transaction? existing;

  @override
  State<TransactionSheet> createState() => _TransactionSheetState();
}

class _TransactionSheetState extends State<TransactionSheet> {
  late TransactionType _type;
  int _walletIndex = 0;
  models.Category? _category;
  late String _amountStr;
  late DateTime _dateTime;
  late final TextEditingController _noteController;

  bool get _isEdit => widget.existing != null;

  /// Bank Jago email-sync rows (integrasi-jago) keep their amount/wallet
  /// as reported by the bank — only note/category/date stay editable.
  bool get _isAmountLocked => widget.existing?.source == TransactionSource.emailSync;

  models.CategoryType get _categoryType => _type == TransactionType.income
      ? models.CategoryType.income
      : models.CategoryType.expense;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _type = existing?.type == TransactionType.income
        ? TransactionType.income
        : TransactionType.expense;
    _amountStr = existing == null ? '' : existing.amount.toString();
    _dateTime = existing?.dateTime ?? DateTime.now();
    _noteController = TextEditingController(text: existing?.note ?? '');
    if (existing != null) {
      final repository = context.read<FinanceRepository>();
      _category = repository.categories
          .where((c) => c.id == existing.categoryId)
          .firstOrNull;
      final walletIdx = repository.wallets.indexWhere(
        (w) => w.id == existing.walletId,
      );
      _walletIndex = walletIdx >= 0 ? walletIdx : 0;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() {
      _dateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _dateTime.hour,
        _dateTime.minute,
      );
    });
  }

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
    if (_isAmountLocked) return;
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
    if (amount == null || amount <= 0) {
      showSnackBarMessage(context, 'Isi nominalnya dulu ya, Bun');
      return;
    }
    if (_category == null) {
      showSnackBarMessage(context, 'Pilih kategorinya dulu ya, Bun');
      return;
    }
    if (wallets.isEmpty) return;

    final wallet = wallets[_walletIndex % wallets.length];
    final note = _noteController.text.trim();
    final existing = widget.existing;
    if (existing != null) {
      await repository.updateTransaction(
        existing.copyWith(
          type: _type,
          amount: amount,
          walletId: wallet.id,
          categoryId: _category!.id,
          dateTime: _dateTime,
          note: note.isEmpty ? null : note,
          clearNote: note.isEmpty,
        ),
      );
    } else {
      final now = DateTime.now();
      await repository.addTransaction(
        Transaction(
          id: const Uuid().v4(),
          type: _type,
          amount: amount,
          walletId: wallet.id,
          categoryId: _category!.id,
          dateTime: _dateTime,
          note: note.isEmpty ? null : note,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final confirmed = await confirmDelete(
      context,
      title: 'Hapus Transaksi?',
      message: 'Catatan yang sudah dihapus tidak bisa dikembalikan, Bun.',
    );
    if (!confirmed || !mounted) return;
    await context.read<FinanceRepository>().deleteTransaction(existing.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<FinanceRepository>();
    final wallets = repository.wallets;
    final wallet = wallets.isEmpty
        ? null
        : wallets[_walletIndex % wallets.length];
    final categories = repository.categories
        .where((c) => c.type == _categoryType)
        .toList();

    return TransactionSheetView(
      isEdit: _isEdit,
      isIncome: _type == TransactionType.income,
      isAmountLocked: _isAmountLocked,
      amountStr: _amountStr,
      categories: categories,
      selectedCategory: _category,
      wallet: wallet,
      dateTime: _dateTime,
      noteController: _noteController,
      onSelectType: _setType,
      onSelectCategory: (cat) => setState(() => _category = cat),
      onTapWallet: _isAmountLocked ? null : () => _cycleWallet(wallets.length),
      onTapDate: _pickDate,
      onKeyTap: _pressKey,
      onClose: () => Navigator.of(context).pop(),
      onDelete: _isEdit ? _delete : null,
    );
  }
}
