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
import 'twemoji_icon.dart';

final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

/// A single row in Dompet's "Riwayat Transaksi" list, followed by a dashed
/// divider.
class TransactionHistoryRow extends StatelessWidget {
  const TransactionHistoryRow({
    super.key,
    required this.transaction,
    required this.category,
    required this.wallet,
    required this.relativeDate,
    required this.palette,
  });

  final Transaction transaction;
  final models.Category? category;
  final Wallet? wallet;
  final String relativeDate;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionType.income;
    final label = category?.name ?? (isIncome ? 'Pemasukan' : 'Pengeluaran');
    final sub = (transaction.note?.isNotEmpty ?? false) ? transaction.note! : (wallet?.name ?? '');
    final iconAsset = category != null ? AppIcons.byIconValue[category!.iconValue] : null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            children: [
              iconAsset != null
                  ? TwemojiIcon(iconAsset, size: 24)
                  : Icon(isIncome ? Icons.arrow_downward : Icons.arrow_upward, size: 22, color: palette.textPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: palette.textPrimary)),
                    Text(
                      '$sub · $relativeDate',
                      style: AppTheme.body(fontSize: 11, fontWeight: FontWeight.bold, color: palette.textSecondary),
                    ),
                  ],
                ),
              ),
              Text(
                '${isIncome ? '+' : '-'}${_currency.format(transaction.amount)}',
                style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: isIncome ? AppColors.gold : AppColors.peach),
              ),
            ],
          ),
        ),
        DashedLine(color: palette.borderStrong),
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
