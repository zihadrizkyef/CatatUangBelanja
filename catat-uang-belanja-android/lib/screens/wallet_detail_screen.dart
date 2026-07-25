import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction.dart';
import '../repositories/finance_repository.dart';
import '../utils/relative_date.dart';
import 'all_transactions_screen.dart';
import 'wallet_detail_view.dart';
import 'wallet_sheet.dart';

/// Full-screen push target for tapping a wallet card on Dompet: that
/// wallet's own transaction history (including transfers in/out), plus an
/// edit action opening [WalletSheet]. Takes a [walletId] rather than a
/// [Wallet] snapshot so it keeps tracking the same wallet across edits, and
/// self-pops if the wallet gets deleted while this screen is open.
class WalletDetailScreen extends StatefulWidget {
  const WalletDetailScreen({super.key, required this.walletId});

  final String walletId;

  @override
  State<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends State<WalletDetailScreen> {
  void _editWallet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WalletSheet(existing: context.read<FinanceRepository>().wallets.where((w) => w.id == widget.walletId).firstOrNull),
    );
  }

  void _openAllTransactions() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => AllTransactionsScreen(initialWalletId: widget.walletId)));
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<FinanceRepository>();
    final wallet = repository.wallets.where((w) => w.id == widget.walletId).firstOrNull;

    if (wallet == null) {
      // The wallet was deleted (from the edit sheet) while this screen was
      // open — pop back to Dompet once the current frame settles.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
      return const SizedBox.shrink();
    }

    final walletsById = {for (final w in repository.wallets) w.id: w};
    final rows = repository.transactions.where((t) => t.walletId == wallet.id || t.targetWalletId == wallet.id).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

    return WalletDetailView(
      wallet: wallet,
      balance: repository.balanceOf(wallet.id),
      transactions: [
        for (final t in rows)
          (
            transaction: t,
            category: repository.categories.where((c) => c.id == t.categoryId).firstOrNull,
            counterpartWallet: t.type == TransactionType.transfer
                ? walletsById[t.walletId == wallet.id ? t.targetWalletId : t.walletId]
                : null,
            isTransferIn: t.type == TransactionType.transfer && t.targetWalletId == wallet.id,
            relativeDate: relativeDateLabel(t.dateTime),
          ),
      ],
      onClose: () => Navigator.of(context).pop(),
      onEdit: _editWallet,
      onSeeAll: rows.isNotEmpty ? _openAllTransactions : null,
    );
  }
}
