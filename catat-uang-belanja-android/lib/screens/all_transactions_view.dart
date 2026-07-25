import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';

import '../models/category.dart' as models;
import '../models/icon_type.dart';
import '../models/transaction.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_dropdown.dart';
import '../widgets/filter_option.dart';
import '../widgets/header_circle_button.dart';
import '../widgets/segment_button.dart';
import '../widgets/transaction_group_list.dart';
import '../widgets/transaction_summary_bar.dart';

/// Matches Semua Transaksi's 3-way type chip row. "Semua" is the only
/// option under which [TransactionType.transfer] rows appear — the two
/// specific filters only match income/expense (doc 4.3: transfers are kept
/// out of income/expense reporting).
enum AtsTypeFilter { all, expense, income }

/// Pure Semua Transaksi layout: header (optionally wallet-scoped with an
/// edit action), search + type/wallet/category filters, a summary bar, and
/// the date-grouped result list. All data/callbacks come from the
/// [AllTransactionsScreen] container — this widget never reads
/// [FinanceRepository] or [Navigator] itself.
class AllTransactionsView extends StatelessWidget {
  const AllTransactionsView({
    super.key,
    required this.title,
    required this.showEditWallet,
    required this.onEditWalletTap,
    required this.onClose,
    required this.searchController,
    required this.typeFilter,
    required this.onSelectTypeFilter,
    required this.walletFilterLabel,
    required this.walletDropdownOpen,
    required this.onToggleWalletDropdown,
    required this.walletDropdownSearchController,
    required this.walletOptions,
    required this.categoryFilterLabel,
    required this.categoryDropdownOpen,
    required this.onToggleCategoryDropdown,
    required this.categoryDropdownSearchController,
    required this.categoryOptions,
    required this.summaryCountText,
    required this.summaryNetText,
    required this.summaryNetColor,
    required this.groups,
  });

  final String title;
  final bool showEditWallet;
  final VoidCallback? onEditWalletTap;
  final VoidCallback onClose;
  final TextEditingController searchController;
  final AtsTypeFilter typeFilter;
  final ValueChanged<AtsTypeFilter> onSelectTypeFilter;
  final String walletFilterLabel;
  final bool walletDropdownOpen;
  final VoidCallback onToggleWalletDropdown;
  final TextEditingController walletDropdownSearchController;
  final List<FilterOption> walletOptions;
  final String categoryFilterLabel;
  final bool categoryDropdownOpen;
  final VoidCallback onToggleCategoryDropdown;
  final TextEditingController categoryDropdownSearchController;
  final List<FilterOption> categoryOptions;
  final String summaryCountText;
  final String summaryNetText;
  final Color summaryNetColor;
  final List<AtsGroup> groups;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final hasResults = groups.isNotEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: AppTheme.accentHeaderOverlay,
      child: Scaffold(
        backgroundColor: palette.screenBg,
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 18, 16, 20),
                color: AppColors.accent,
                child: Row(
                  children: [
                    HeaderCircleButton(icon: Icons.chevron_left, onTap: onClose),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(title, overflow: TextOverflow.ellipsis, style: AppTheme.heading(fontSize: 18, color: Colors.white)),
                    ),
                    if (showEditWallet) HeaderCircleButton(icon: Icons.edit_rounded, iconSize: 16, onTap: onEditWalletTap ?? () {}),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      style: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: palette.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Cari transaksi…',
                        hintStyle: AppTheme.body(fontSize: 13, fontWeight: FontWeight.bold, color: palette.textSecondary),
                        prefixIcon: Icon(Icons.search, size: 18, color: palette.textSecondary),
                        filled: true,
                        fillColor: palette.chipNeutral,
                        contentPadding: const EdgeInsets.symmetric(vertical: 11),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: palette.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: palette.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.accent, width: 2)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: palette.chipNeutral, borderRadius: BorderRadius.circular(14)),
                      child: Row(
                        children: [
                          for (final opt in AtsTypeFilter.values)
                            Expanded(
                              child: SegmentButton(
                                label: _typeFilterLabel(opt),
                                selected: typeFilter == opt,
                                color: AppColors.accent,
                                onTap: () => onSelectTypeFilter(opt),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: FilterDropdown(
                            prefixEmoji: '👛',
                            label: walletFilterLabel,
                            isOpen: walletDropdownOpen,
                            onToggle: onToggleWalletDropdown,
                            searchController: walletDropdownSearchController,
                            searchHint: 'Cari dompet…',
                            options: walletOptions,
                            noMatchesText: 'Dompet tidak ditemukan',
                            palette: palette,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilterDropdown(
                            prefixEmoji: '🏷️',
                            label: categoryFilterLabel,
                            isOpen: categoryDropdownOpen,
                            onToggle: onToggleCategoryDropdown,
                            searchController: categoryDropdownSearchController,
                            searchHint: 'Cari kategori…',
                            options: categoryOptions,
                            noMatchesText: 'Kategori tidak ditemukan',
                            palette: palette,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TransactionSummaryBar(countText: summaryCountText, netText: summaryNetText, netColor: summaryNetColor, palette: palette),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  children: [
                    if (hasResults)
                      TransactionGroupList(groups: groups, palette: palette)
                    else
                      EmptyState(
                        palette: palette,
                        icon: AppIcons.emptyReceipt,
                        iconSize: 44,
                        bordered: false,
                        title: 'Tidak ada transaksi yang cocok, Bun.',
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

String _typeFilterLabel(AtsTypeFilter filter) => switch (filter) {
      AtsTypeFilter.all => 'Semua',
      AtsTypeFilter.expense => 'Pengeluaran',
      AtsTypeFilter.income => 'Pemasukan',
    };

final _previewCategory = const models.Category(
  id: 'preview-category',
  name: 'Belanja Dapur',
  type: models.CategoryType.expense,
  color: '#E8637C',
  iconType: IconType.system,
  iconValue: 'category_kitchen',
);

@Preview(name: 'AllTransactionsView · semua')
Widget previewAllTransactionsView() {
  return AllTransactionsView(
    title: 'Semua Transaksi',
    showEditWallet: false,
    onEditWalletTap: null,
    onClose: () {},
    searchController: TextEditingController(),
    typeFilter: AtsTypeFilter.all,
    onSelectTypeFilter: (_) {},
    walletFilterLabel: 'Semua Dompet',
    walletDropdownOpen: false,
    onToggleWalletDropdown: () {},
    walletDropdownSearchController: TextEditingController(),
    walletOptions: const [],
    categoryFilterLabel: 'Semua Kategori',
    categoryDropdownOpen: false,
    onToggleCategoryDropdown: () {},
    categoryDropdownSearchController: TextEditingController(),
    categoryOptions: const [],
    summaryCountText: '3 transaksi',
    summaryNetText: '-Rp105.000',
    summaryNetColor: AppColors.peach,
    groups: [
      (
        dateLabel: 'Hari ini',
        items: [
          (
            transaction: Transaction(
              id: 'preview-tx-1',
              type: TransactionType.expense,
              amount: 85000,
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
  );
}

@Preview(name: 'AllTransactionsView · scoped ke dompet, dropdown terbuka')
Widget previewAllTransactionsViewWalletScoped() {
  return AllTransactionsView(
    title: 'Dompet Tunai',
    showEditWallet: true,
    onEditWalletTap: () {},
    onClose: () {},
    searchController: TextEditingController(),
    typeFilter: AtsTypeFilter.expense,
    onSelectTypeFilter: (_) {},
    walletFilterLabel: 'Dompet Tunai',
    walletDropdownOpen: true,
    onToggleWalletDropdown: () {},
    walletDropdownSearchController: TextEditingController(),
    walletOptions: [
      (id: '', label: 'Semua Dompet', iconAsset: null, selected: false, onSelect: () {}),
      (id: 'w1', label: 'Dompet Tunai', iconAsset: null, selected: true, onSelect: () {}),
    ],
    categoryFilterLabel: 'Semua Kategori',
    categoryDropdownOpen: false,
    onToggleCategoryDropdown: () {},
    categoryDropdownSearchController: TextEditingController(),
    categoryOptions: const [],
    summaryCountText: '0 transaksi',
    summaryNetText: '+Rp0',
    summaryNetColor: AppColors.gold,
    groups: const [],
  );
}
