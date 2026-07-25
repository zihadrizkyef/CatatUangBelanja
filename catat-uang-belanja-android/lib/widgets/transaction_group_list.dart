import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../models/category.dart' as models;
import '../models/icon_type.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../theme/app_theme.dart';
import 'transaction_history_row.dart';

/// A single row in a [TransactionGroupList] group — no `relativeDate` since
/// the group's own date-label header already carries that.
typedef AtsTransactionRowData = ({
  Transaction transaction,
  models.Category? category,
  Wallet? counterpartWallet,
  bool isTransferIn,
  VoidCallback onTap,
});

typedef AtsGroup = ({String dateLabel, List<AtsTransactionRowData> items});

/// Semua Transaksi's filtered results, grouped under uppercase date-label
/// headers ("HARI INI", "KEMARIN", ...), each group rendered as one card of
/// [TransactionHistoryRow]s.
class TransactionGroupList extends StatelessWidget {
  const TransactionGroupList({super.key, required this.groups, required this.palette});

  final List<AtsGroup> groups;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final group in groups) ...[
          Semantics(
            header: true,
            container: true,
            child: Text(
              group.dateLabel.toUpperCase(),
              style: AppTheme.body(fontSize: 11, fontWeight: FontWeight.bold, color: palette.textSecondary).copyWith(letterSpacing: 0.5),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: palette.cardBg,
              border: Border.all(color: palette.border),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                for (var i = 0; i < group.items.length; i++)
                  TransactionHistoryRow(
                    transaction: group.items[i].transaction,
                    category: group.items[i].category,
                    wallet: group.items[i].counterpartWallet,
                    isTransferIn: group.items[i].isTransferIn,
                    palette: palette,
                    onTap: group.items[i].onTap,
                    showDivider: i < group.items.length - 1,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
      ],
    );
  }
}

final _previewCategory = const models.Category(
  id: 'preview-category',
  name: 'Dapur',
  type: models.CategoryType.expense,
  color: '#E8637C',
  iconType: IconType.system,
  iconValue: 'category_kitchen',
);

@Preview(name: 'TransactionGroupList')
Widget previewTransactionGroupList() {
  return TransactionGroupList(
    groups: [
      (
        dateLabel: 'Hari ini',
        items: [
          (
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
            category: _previewCategory,
            counterpartWallet: null,
            isTransferIn: false,
            onTap: () {},
          ),
        ],
      ),
    ],
    palette: AppPalette.light,
  );
}
