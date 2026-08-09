import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:intl/intl.dart';

import '../models/category.dart' as models;
import '../models/icon_type.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import 'openmoji_icon.dart';
import '../theme/app_theme.dart';

final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

/// A single row in Beranda's "Transaksi Terbaru" card list.
class HomeTransactionRow extends StatelessWidget {
  const HomeTransactionRow({
    super.key,
    required this.transaction,
    required this.category,
    required this.wallet,
    this.targetWallet,
    required this.relativeDate,
    required this.palette,
    this.onTap,
  });

  final Transaction transaction;
  final models.Category? category;
  final Wallet? wallet;
  final Wallet? targetWallet;
  final String relativeDate;
  final AppPalette palette;

  /// Opens the transaction for editing when set, mirroring
  /// `TransactionHistoryRow`'s behavior in Semua Transaksi.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isTransfer = transaction.type == TransactionType.transfer;
    final isIncome = transaction.type == TransactionType.income;
    final categoryLabel = category?.name ?? (isIncome ? 'Pemasukan' : 'Pengeluaran');
    final hasItemName = transaction.itemName?.isNotEmpty ?? false;
    final label = isTransfer
        ? 'Transfer ke ${targetWallet?.name ?? '-'}'
        : (hasItemName ? transaction.itemName! : categoryLabel);
    final sub = isTransfer
        ? ''
        : (hasItemName
            ? categoryLabel
            : ((transaction.note?.isNotEmpty ?? false) ? transaction.note! : (wallet?.name ?? '')));
    final subLine = [sub, relativeDate].where((s) => s.isNotEmpty).join(' · ');
    final iconBg = category != null ? Color(int.parse(category!.color.replaceFirst('#', '0xFF'))) : palette.chipNeutral;
    final iconAsset = category != null ? AppIcons.byIconValue[category!.iconValue] : null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: palette.cardShadow, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: palette.cardBg,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: iconAsset != null
                      ? OpenMojiIcon(iconAsset, size: 39)
                      : Icon(
                          isTransfer ? Icons.swap_horiz_rounded : (isIncome ? Icons.arrow_downward : Icons.arrow_upward),
                          size: 24,
                          color: palette.textPrimary,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: AppTheme.body(fontSize: 14, fontWeight: FontWeight.bold, color: palette.textPrimary)),
                      Text(subLine, style: AppTheme.body(fontSize: 12, fontWeight: FontWeight.bold, color: palette.textSecondary)),
                    ],
                  ),
                ),
                Text(
                  '${isIncome ? '+' : '-'}${_currency.format(transaction.amount)}',
                  style: AppTheme.body(fontSize: 14, fontWeight: FontWeight.bold, color: isIncome ? AppColors.gold : AppColors.peach),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

@Preview(name: 'HomeTransactionRow')
Widget previewHomeTransactionRow() {
  return HomeTransactionRow(
    transaction: Transaction(
      id: 'preview-tx',
      type: TransactionType.expense,
      amount: 45000,
      walletId: 'preview-wallet',
      categoryId: 'preview-category',
      dateTime: DateTime(2026, 7, 6),
      createdAt: DateTime(2026, 7, 6),
      updatedAt: DateTime(2026, 7, 6),
    ),
    category: const models.Category(
      id: 'preview-category',
      name: 'Dapur',
      type: models.CategoryType.expense,
      color: '#E8637C',
      iconType: IconType.system,
      iconValue: 'category_kitchen',
    ),
    wallet: Wallet(
      id: 'preview-wallet',
      name: 'Dompet Tunai',
      type: WalletType.cash,
      color: '#E8637C',
      iconType: IconType.system,
      iconValue: 'wallet_cash',
      createdAt: DateTime(2026, 1, 1),
    ),
    relativeDate: 'Hari ini',
    palette: AppPalette.light,
  );
}

@Preview(name: 'HomeTransactionRow · transfer')
Widget previewHomeTransactionRowTransfer() {
  return HomeTransactionRow(
    transaction: Transaction(
      id: 'preview-transfer',
      type: TransactionType.transfer,
      amount: 200000,
      walletId: 'preview-wallet-cash',
      targetWalletId: 'preview-wallet-bank',
      dateTime: DateTime(2026, 7, 6),
      createdAt: DateTime(2026, 7, 6),
      updatedAt: DateTime(2026, 7, 6),
    ),
    category: null,
    wallet: Wallet(
      id: 'preview-wallet-cash',
      name: 'Dompet Tunai',
      type: WalletType.cash,
      color: '#E8637C',
      iconType: IconType.system,
      iconValue: 'wallet_cash',
      createdAt: DateTime(2026, 1, 1),
    ),
    targetWallet: Wallet(
      id: 'preview-wallet-bank',
      name: 'Rekening Bank',
      type: WalletType.bank,
      color: '#DCD3F0',
      iconType: IconType.system,
      iconValue: 'wallet_bank',
      createdAt: DateTime(2026, 1, 1),
    ),
    relativeDate: 'Hari ini',
    palette: AppPalette.light,
  );
}
