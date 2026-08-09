import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:intl/intl.dart';

import '../models/category.dart' as models;
import '../models/icon_type.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import 'dashed_line.dart';
import 'jago_badge.dart';
import 'openmoji_icon.dart';

final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

/// A single row in a "Riwayat Transaksi" list, followed by a dashed divider.
/// [wallet] means different things depending on [transaction]'s type: for
/// income/expense it's the transaction's own wallet (shown as a sub-label
/// when there's no note); for a transfer it's the *counterpart* wallet
/// (source or destination, whichever isn't the wallet this list is scoped
/// to), used to render "Transfer dari/ke `<wallet>`". [isTransferIn] tells a
/// transfer row apart from an outgoing one — irrelevant for income/expense.
/// [relativeDate] is optional so callers that already group rows under a
/// date header (e.g. Semua Transaksi) can omit the redundant per-row date.
/// [onTap] is optional — when set, the row opens (e.g.) an edit sheet.
/// [showDivider] should be false for the last row in a card/group so the
/// divider doesn't dangle just above the container's own bottom edge.
class TransactionHistoryRow extends StatelessWidget {
  const TransactionHistoryRow({
    super.key,
    required this.transaction,
    required this.category,
    required this.wallet,
    required this.palette,
    this.relativeDate,
    this.isTransferIn = false,
    this.onTap,
    this.showDivider = true,
  });

  final Transaction transaction;
  final models.Category? category;
  final Wallet? wallet;
  final String? relativeDate;
  final AppPalette palette;
  final bool isTransferIn;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final isTransfer = transaction.type == TransactionType.transfer;
    final isPositive = transaction.type == TransactionType.income || (isTransfer && isTransferIn);
    final label = isTransfer
        ? (isTransferIn ? 'Transfer dari ${wallet?.name ?? '-'}' : 'Transfer ke ${wallet?.name ?? '-'}')
        : (category?.name ?? (isPositive ? 'Pemasukan' : 'Pengeluaran'));
    final sub = (transaction.note?.isNotEmpty ?? false) ? transaction.note! : (isTransfer ? '' : (wallet?.name ?? ''));
    final subLine = [sub, relativeDate ?? ''].where((s) => s.isNotEmpty).join(' · ');
    final iconAsset = category != null ? AppIcons.byIconValue[category!.iconValue] : null;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Row(
                children: [
                  iconAsset != null
                      ? OpenMojiIcon(iconAsset, size: 42)
                      : Icon(
                          isTransfer ? Icons.swap_horiz_rounded : (isPositive ? Icons.arrow_downward : Icons.arrow_upward),
                          size: 26,
                          color: palette.textPrimary,
                        ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                label,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: palette.textPrimary),
                              ),
                            ),
                            if (transaction.source == TransactionSource.emailSync) ...[
                              const SizedBox(width: 6),
                              const JagoBadge(),
                            ],
                          ],
                        ),
                        if (subLine.isNotEmpty)
                          Text(subLine, style: AppTheme.body(fontSize: 11, fontWeight: FontWeight.bold, color: palette.textSecondary)),
                      ],
                    ),
                  ),
                  Text(
                    '${isPositive ? '+' : '-'}${_currency.format(transaction.amount)}',
                    style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: isPositive ? AppColors.gold : AppColors.peach),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showDivider) DashedLine(color: palette.borderStrong),
      ],
    );
  }
}

@Preview(name: 'TransactionHistoryRow')
Widget previewTransactionHistoryRow() {
  return TransactionHistoryRow(
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

@Preview(name: 'TransactionHistoryRow · transfer masuk')
Widget previewTransactionHistoryRowTransferIn() {
  return TransactionHistoryRow(
    transaction: Transaction(
      id: 'preview-transfer',
      type: TransactionType.transfer,
      amount: 500000,
      walletId: 'preview-wallet-bank',
      targetWalletId: 'preview-wallet-cash',
      dateTime: DateTime(2026, 7, 6),
      createdAt: DateTime(2026, 7, 6),
      updatedAt: DateTime(2026, 7, 6),
    ),
    category: null,
    wallet: Wallet(
      id: 'preview-wallet-bank',
      name: 'Rekening Bank',
      type: WalletType.bank,
      color: '#DCD3F0',
      iconType: IconType.system,
      iconValue: 'wallet_bank',
      createdAt: DateTime(2026, 1, 1),
    ),
    isTransferIn: true,
    relativeDate: 'Hari ini',
    palette: AppPalette.light,
  );
}
