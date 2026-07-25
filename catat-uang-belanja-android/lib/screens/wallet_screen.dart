import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/wallet.dart';
import '../repositories/finance_repository.dart';
import 'transfer_sheet.dart';
import 'wallet_detail_screen.dart';
import 'wallet_sheet.dart';
import 'wallet_view.dart';

/// Dompet tab container: reads [FinanceRepository] for the (search-filtered)
/// wallet list and combined balance, wires up the add [WalletSheet] and
/// [TransferSheet], and pushes [WalletDetailScreen] when a wallet is
/// tapped; hands the rest to [WalletView].
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddWalletSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const WalletSheet(),
    );
  }

  void _openTransferSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TransferSheet(),
    );
  }

  void _openWalletDetail(Wallet wallet) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => WalletDetailScreen(walletId: wallet.id)));
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<FinanceRepository>();
    final allWallets = repository.wallets.where((w) => !w.isArchived).toList();
    final query = _searchController.text.trim().toLowerCase();
    final filteredWallets =
        query.isEmpty ? allWallets : allWallets.where((w) => w.name.toLowerCase().contains(query)).toList();

    return WalletView(
      totalBalance: repository.totalBalance,
      hasWallets: allWallets.isNotEmpty,
      wallets: filteredWallets,
      walletBalances: [for (final w in filteredWallets) repository.balanceOf(w.id)],
      canTransfer: allWallets.length >= 2,
      searchController: _searchController,
      onTapAddWallet: _openAddWalletSheet,
      onTapTransfer: _openTransferSheet,
      onTapWallet: _openWalletDetail,
    );
  }
}
