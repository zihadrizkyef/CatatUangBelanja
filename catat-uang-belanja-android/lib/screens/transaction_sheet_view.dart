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
import '../utils/sheet_padding.dart';
import '../widgets/numeric_keypad.dart';
import '../widgets/segment_button.dart';
import '../widgets/openmoji_icon.dart';

String _dateChipLabel(DateTime date) {
  final now = DateTime.now();
  final isToday =
      date.year == now.year && date.month == now.month && date.day == now.day;
  return isToday ? 'Hari ini' : DateFormat('d MMM yyyy', 'id_ID').format(date);
}

/// Pure layout for [TransactionSheet]: expense/income toggle, amount keypad,
/// category grid, and a wallet chip. All data/callbacks come from the
/// [TransactionSheet] container — this widget never reads
/// [FinanceRepository] or [Navigator] itself.
class TransactionSheetView extends StatelessWidget {
  const TransactionSheetView({
    super.key,
    required this.isEdit,
    required this.isIncome,
    required this.amountStr,
    required this.selectedCategory,
    required this.wallet,
    required this.dateTime,
    required this.itemNameController,
    required this.noteController,
    required this.onSelectType,
    required this.onTapCategory,
    required this.onTapWallet,
    required this.onTapDate,
    required this.onKeyTap,
    required this.onClose,
    this.onDelete,
  });

  final bool isEdit;
  final bool isIncome;
  final String amountStr;
  final models.Category? selectedCategory;
  final Wallet? wallet;
  final DateTime dateTime;
  final TextEditingController itemNameController;
  final TextEditingController noteController;
  final ValueChanged<TransactionType> onSelectType;
  final VoidCallback onTapCategory;
  final VoidCallback onTapWallet;
  final VoidCallback onTapDate;
  final ValueChanged<String> onKeyTap;
  final VoidCallback onClose;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final accent = isIncome ? AppColors.gold : AppColors.peach;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: palette.cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(18, 18, 18, sheetBottomPadding(context)),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit
                      ? 'Edit Transaksi'
                      : (isIncome ? 'Tambah Pemasukan' : 'Tambah Pengeluaran'),
                  style: AppTheme.heading(
                    fontSize: 17,
                    color: palette.textPrimary,
                  ),
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
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: palette.chipNeutral,
                borderRadius: BorderRadius.circular(14),
              ),
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
            Material(
              color: palette.chipNeutral,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onTapCategory,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      if (selectedCategory != null &&
                          AppIcons.byIconValue[selectedCategory!.iconValue] !=
                              null)
                        OpenMojiIcon(
                          AppIcons.byIconValue[selectedCategory!.iconValue]!,
                          size: 28,
                        )
                      else
                        Icon(
                          Icons.category_rounded,
                          size: 22,
                          color: palette.textSecondary,
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          selectedCategory?.name ?? 'Pilih kategori, yuk!',
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.body(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: selectedCategory != null
                                ? palette.textPrimary
                                : palette.textSecondary,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: palette.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Material(
                    color: palette.chipNeutral,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: onTapDate,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 15,
                              color: palette.textPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _dateChipLabel(dateTime),
                              style: AppTheme.body(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: palette.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (wallet != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Material(
                      color: palette.chipNeutral,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: onTapWallet,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (AppIcons.byIconValue[wallet!.iconValue] !=
                                  null)
                                OpenMojiIcon(
                                  AppIcons.byIconValue[wallet!.iconValue]!,
                                  size: 30,
                                ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  wallet!.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTheme.body(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: palette.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: itemNameController,
              style: AppTheme.body(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: palette.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Nama Item (opsional)',
                hintStyle: AppTheme.body(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: palette.textSecondary,
                ),
                filled: true,
                fillColor: palette.chipNeutral,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteController,
              style: AppTheme.body(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: palette.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Catatan (opsional)',
                hintStyle: AppTheme.body(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: palette.textSecondary,
                ),
                filled: true,
                fillColor: palette.chipNeutral,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (isEdit) ...[
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: onDelete,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.accent),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        'Hapus Transaksi',
                        textAlign: TextAlign.center,
                        style: AppTheme.body(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            NumericKeypad(
              confirmColor: accent,
              palette: palette,
              onKeyTap: onKeyTap,
            ),
          ],
        ),
      ),
    );
  }
}

final _previewSheetCategory = const models.Category(
  id: 'preview-category',
  name: 'Dapur',
  type: models.CategoryType.expense,
  color: '#E8637C',
  iconType: IconType.system,
  iconValue: 'category_kitchen',
);

final _previewSheetWallet = Wallet(
  id: 'preview-wallet',
  name: 'Dompet Tunai',
  type: WalletType.cash,
  color: '#E8637C',
  iconType: IconType.system,
  iconValue: 'wallet_cash',
  createdAt: DateTime(2026, 1, 1),
);

@Preview(name: 'TransactionSheetView · pengeluaran')
Widget previewTransactionSheetViewExpense() {
  return TransactionSheetView(
    isEdit: false,
    isIncome: false,
    amountStr: '45000',
    selectedCategory: null,
    wallet: _previewSheetWallet,
    dateTime: DateTime.now(),
    itemNameController: TextEditingController(),
    noteController: TextEditingController(),
    onSelectType: (_) {},
    onTapCategory: () {},
    onTapWallet: () {},
    onTapDate: () {},
    onKeyTap: (_) {},
    onClose: () {},
  );
}

@Preview(name: 'TransactionSheetView · edit')
Widget previewTransactionSheetViewEdit() {
  return TransactionSheetView(
    isEdit: true,
    isIncome: false,
    amountStr: '45000',
    selectedCategory: _previewSheetCategory,
    wallet: _previewSheetWallet,
    dateTime: DateTime(2026, 7, 4),
    itemNameController: TextEditingController(text: 'Sayur & lauk'),
    noteController: TextEditingController(
      text: 'Belanja sayur & lauk di pasar',
    ),
    onSelectType: (_) {},
    onTapCategory: () {},
    onTapWallet: () {},
    onTapDate: () {},
    onKeyTap: (_) {},
    onClose: () {},
    onDelete: () {},
  );
}
