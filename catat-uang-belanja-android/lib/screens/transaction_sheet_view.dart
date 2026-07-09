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
import '../widgets/category_chip.dart';
import '../widgets/numeric_keypad.dart';
import '../widgets/segment_button.dart';
import '../widgets/openmoji_icon.dart';

/// Pure layout for [TransactionSheet]: expense/income toggle, amount keypad,
/// category grid, and a wallet chip. All data/callbacks come from the
/// [TransactionSheet] container — this widget never reads
/// [FinanceRepository] or [Navigator] itself.
class TransactionSheetView extends StatelessWidget {
  const TransactionSheetView({
    super.key,
    required this.isIncome,
    required this.amountStr,
    required this.categories,
    required this.selectedCategory,
    required this.wallet,
    required this.onSelectType,
    required this.onSelectCategory,
    required this.onTapWallet,
    required this.onKeyTap,
    required this.onClose,
  });

  final bool isIncome;
  final String amountStr;
  final List<models.Category> categories;
  final models.Category? selectedCategory;
  final Wallet? wallet;
  final ValueChanged<TransactionType> onSelectType;
  final ValueChanged<models.Category> onSelectCategory;
  final VoidCallback onTapWallet;
  final ValueChanged<String> onKeyTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final accent = isIncome ? AppColors.gold : AppColors.peach;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(18, 18, 18, 22 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isIncome ? 'Tambah Pemasukan' : 'Tambah Pengeluaran',
                  style: AppTheme.heading(fontSize: 17, color: palette.textPrimary),
                ),
                Material(
                  color: palette.warningBg,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onClose,
                    child: SizedBox(
                      width: 38,
                      height: 38,
                      child: Icon(Icons.close, size: 20, color: palette.textPrimary),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: palette.chipNeutral, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Expanded(
                    child: SegmentButton(
                      label: 'Pengeluaran',
                      selected: !isIncome,
                      color: AppColors.peach,
                      onTap: () => onSelectType(TransactionType.expense),
                    ),
                  ),
                  Expanded(
                    child: SegmentButton(
                      label: 'Pemasukan',
                      selected: isIncome,
                      color: AppColors.gold,
                      onTap: () => onSelectType(TransactionType.income),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Rp ${amountStr.isEmpty ? '0' : NumberFormat('#,###', 'id_ID').format(int.parse(amountStr))}',
              textAlign: TextAlign.center,
              style: AppTheme.heading(fontSize: 30, color: palette.textPrimary),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cat in categories)
                  CategoryChip(
                    category: cat,
                    selected: selectedCategory?.id == cat.id,
                    selectedColor: accent,
                    palette: palette,
                    onTap: () => onSelectCategory(cat),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (wallet != null)
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: palette.chipNeutral,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onTapWallet,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          if (AppIcons.byIconValue[wallet!.iconValue] != null)
                            OpenMojiIcon(AppIcons.byIconValue[wallet!.iconValue]!, size: 25),
                          const SizedBox(width: 8),
                          Text(
                            'Dompet: ${wallet!.name}',
                            style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: palette.textPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            NumericKeypad(confirmColor: accent, palette: palette, onKeyTap: onKeyTap),
          ],
        ),
      ),
    );
  }
}

@Preview(name: 'TransactionSheetView · pengeluaran')
Widget previewTransactionSheetViewExpense() {
  return TransactionSheetView(
    isIncome: false,
    amountStr: '45000',
    categories: const [
      models.Category(
        id: 'preview-category',
        name: 'Dapur',
        type: models.CategoryType.expense,
        color: '#E8637C',
        iconType: IconType.system,
        iconValue: 'category_kitchen',
      ),
    ],
    selectedCategory: null,
    wallet: Wallet(
      id: 'preview-wallet',
      name: 'Dompet Tunai',
      type: WalletType.cash,
      color: '#E8637C',
      iconType: IconType.system,
      iconValue: 'wallet_cash',
      createdAt: DateTime(2026, 1, 1),
    ),
    onSelectType: (_) {},
    onSelectCategory: (_) {},
    onTapWallet: () {},
    onKeyTap: (_) {},
    onClose: () {},
  );
}
