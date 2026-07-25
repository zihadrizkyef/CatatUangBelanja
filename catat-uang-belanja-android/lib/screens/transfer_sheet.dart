import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/wallet.dart';
import '../repositories/finance_repository.dart';
import '../theme/app_theme.dart';
import '../utils/snackbar.dart';
import 'transfer_sheet_view.dart';

final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

/// Pindah-uang-antar-dompet bottom sheet container (doc 4.3): amount keypad
/// plus "Dari"/"Ke" wallet pickers that cycle through the wallet list on
/// tap. Reads/writes [FinanceRepository] and wires up the sheet's
/// [Navigator] dismissal; hands the rest to [TransferSheetView].
class TransferSheet extends StatefulWidget {
  const TransferSheet({super.key});

  @override
  State<TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends State<TransferSheet> {
  int _fromIndex = 0;
  int _toIndex = 1;
  String _amountStr = '';

  void _cycleFrom(int walletCount) {
    setState(() {
      _fromIndex = (_fromIndex + 1) % walletCount;
      if (_fromIndex == _toIndex) _fromIndex = (_fromIndex + 1) % walletCount;
    });
  }

  void _cycleTo(int walletCount) {
    setState(() {
      _toIndex = (_toIndex + 1) % walletCount;
      if (_toIndex == _fromIndex) _toIndex = (_toIndex + 1) % walletCount;
    });
  }

  void _pressKey(String k, List<Wallet> wallets) {
    if (k == '✓') {
      _save(wallets);
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

  Future<void> _save(List<Wallet> wallets) async {
    final amount = int.tryParse(_amountStr);
    if (amount == null || amount <= 0) {
      showSnackBarMessage(context, 'Isi nominalnya dulu ya, Bun');
      return;
    }
    final from = wallets[_fromIndex];
    final to = wallets[_toIndex];
    if (from.id == to.id) {
      showSnackBarMessage(context, 'Dompet asal dan tujuan tidak boleh sama, Bun');
      return;
    }

    final repository = context.read<FinanceRepository>();
    final resultingBalance = repository.balanceOf(from.id) - amount;
    if (resultingBalance < 0) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Saldo Akan Minus', style: AppTheme.heading(fontSize: 18)),
          content: Text(
            'Saldo "${from.name}" akan jadi ${_currency.format(resultingBalance)} setelah transfer ini, Bun. Lanjutkan?',
            style: AppTheme.body(fontSize: 13),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Batal')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Lanjutkan')),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    await repository.addTransfer(
          fromWalletId: from.id,
          toWalletId: to.id,
          amount: amount,
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<FinanceRepository>();
    final wallets = repository.wallets.where((w) => !w.isArchived).toList();
    final fromIndex = _fromIndex < wallets.length ? _fromIndex : 0;
    final toIndex = _toIndex < wallets.length ? _toIndex : 0;

    return TransferSheetView(
      fromWallet: wallets.isEmpty ? null : wallets[fromIndex],
      toWallet: wallets.isEmpty ? null : wallets[toIndex],
      amountStr: _amountStr,
      onCycleFrom: wallets.length > 1 ? () => _cycleFrom(wallets.length) : null,
      onCycleTo: wallets.length > 1 ? () => _cycleTo(wallets.length) : null,
      onKeyTap: (k) => _pressKey(k, wallets),
      onClose: () => Navigator.of(context).pop(),
    );
  }
}
