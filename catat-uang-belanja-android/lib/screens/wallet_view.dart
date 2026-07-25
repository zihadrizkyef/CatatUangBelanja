import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:intl/intl.dart';

import '../models/icon_type.dart';
import '../models/wallet.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/dashed_line.dart';
import '../widgets/empty_state.dart';
import '../widgets/openmoji_icon.dart';
import '../widgets/wallet_card.dart';

final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

/// Pure Dompet layout: hero header with the combined balance across all
/// wallets, and the (search-filterable) wallet list. All data and callbacks
/// come from the [WalletScreen] container — this widget never reads
/// [FinanceRepository] or [ScaffoldMessenger] itself.
class WalletView extends StatelessWidget {
  const WalletView({
    super.key,
    required this.totalBalance,
    required this.hasWallets,
    required this.wallets,
    required this.walletBalances,
    required this.canTransfer,
    required this.searchController,
    required this.onTapAddWallet,
    required this.onTapTransfer,
    required this.onTapWallet,
  });

  final int totalBalance;

  /// Whether the household has any (non-archived) wallet at all — controls
  /// the "belum ada dompet" empty state, distinct from a search yielding no
  /// results ([wallets] empty while this stays true).
  final bool hasWallets;
  final List<Wallet> wallets;
  final List<int> walletBalances;

  /// Whether there are enough wallets (2+) for a transfer to make sense.
  final bool canTransfer;
  final TextEditingController searchController;
  final VoidCallback onTapAddWallet;
  final VoidCallback onTapTransfer;
  final ValueChanged<Wallet> onTapWallet;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final noSearchResults = hasWallets && wallets.isEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.accentHeaderOverlay,
      child: Scaffold(
        backgroundColor: palette.screenBg,
        body: SafeArea(
          top: false,
          bottom: false,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 22, 20, 26),
                color: AppColors.accent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dompet 👛', style: AppTheme.heading(fontSize: 21, color: Colors.white)),
                    const SizedBox(height: 16),
                    DashedLine(color: Colors.white.withValues(alpha: 0.4)),
                    const SizedBox(height: 14),
                    Text(
                      'Total di Semua Dompet',
                      style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white.withValues(alpha: 0.85)),
                    ),
                    Text(_currency.format(totalBalance), style: AppTheme.heading(fontSize: 34, color: Colors.white)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text('Dompet Saya', style: AppTheme.heading(fontSize: 13, color: palette.textPrimary)),
                        ),
                        if (canTransfer) ...[
                          Material(
                            color: palette.chipNeutral,
                            borderRadius: BorderRadius.circular(15),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(15),
                              onTap: onTapTransfer,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const OpenMojiIcon(AppIcons.transfer, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Transfer',
                                      style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: palette.textPrimary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Material(
                          color: palette.warningBg,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onTapAddWallet,
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: Icon(Icons.add, size: 18, color: palette.warningText),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (hasWallets)
                      TextField(
                        controller: searchController,
                        style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: palette.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Cari dompet…',
                          hintStyle: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: palette.textSecondary),
                          prefixIcon: Icon(Icons.search, size: 18, color: palette.textSecondary),
                          filled: true,
                          fillColor: palette.chipNeutral,
                          contentPadding: const EdgeInsets.symmetric(vertical: 11),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: palette.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: palette.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.accent, width: 2),
                          ),
                        ),
                      ),
                    if (hasWallets) const SizedBox(height: 12),
                    if (!hasWallets)
                      EmptyState(
                        palette: palette,
                        icon: AppIcons.wallet,
                        iconSize: 42,
                        title: 'Belum ada dompet, Bun. Yuk tambah yang pertama.',
                      )
                    else if (noSearchResults)
                      EmptyState(
                        palette: palette,
                        icon: AppIcons.wallet,
                        iconSize: 34,
                        bordered: false,
                        title: 'Dompet tidak ditemukan.',
                      )
                    else
                      for (var i = 0; i < wallets.length; i++)
                        WalletCard(
                          wallet: wallets[i],
                          balance: walletBalances[i],
                          palette: palette,
                          onTap: () => onTapWallet(wallets[i]),
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

final _previewWallet = Wallet(
  id: 'preview-wallet',
  name: 'Dompet Tunai',
  type: WalletType.cash,
  color: '#E8637C',
  iconType: IconType.system,
  iconValue: 'wallet_cash',
  createdAt: DateTime(2026, 1, 1),
);

@Preview(name: 'WalletView')
Widget previewWalletView() {
  return WalletView(
    totalBalance: 2450000,
    hasWallets: true,
    wallets: [_previewWallet],
    walletBalances: const [2450000],
    canTransfer: false,
    searchController: TextEditingController(),
    onTapAddWallet: () {},
    onTapTransfer: () {},
    onTapWallet: (_) {},
  );
}

@Preview(name: 'WalletView · kosong')
Widget previewWalletViewEmpty() {
  return WalletView(
    totalBalance: 0,
    hasWallets: false,
    wallets: const [],
    walletBalances: const [],
    canTransfer: false,
    searchController: TextEditingController(),
    onTapAddWallet: () {},
    onTapTransfer: () {},
    onTapWallet: (_) {},
  );
}

@Preview(name: 'WalletView · pencarian kosong')
Widget previewWalletViewNoSearchResults() {
  return WalletView(
    totalBalance: 2450000,
    hasWallets: true,
    wallets: const [],
    walletBalances: const [],
    canTransfer: false,
    searchController: TextEditingController(text: 'xyz'),
    onTapAddWallet: () {},
    onTapTransfer: () {},
    onTapWallet: (_) {},
  );
}
