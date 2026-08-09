import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/category.dart' as models;
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../repositories/finance_repository.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';
import '../utils/relative_date.dart';
import '../widgets/filter_option.dart';
import '../widgets/transaction_group_list.dart';
import 'all_transactions_view.dart';
import 'transaction_sheet.dart';
import 'wallet_sheet.dart';

final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

/// Semua Transaksi (doc 7.x "Lihat Semua"): search + type/wallet/category
/// filters over every transaction, grouped by date, with a count/net
/// summary. Opened globally from Beranda's "Lihat semua →", or scoped to one
/// wallet (locked title, edit-wallet header action) from Dompet detail's
/// "Lihat Semua". Reads/writes [FinanceRepository] and wires up
/// [TransactionSheet]/[WalletSheet]; hands the rest to [AllTransactionsView].
class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key, this.initialWalletId});

  final String? initialWalletId;

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  final _searchController = TextEditingController();
  final _walletDropdownSearchController = TextEditingController();
  final _categoryDropdownSearchController = TextEditingController();
  AtsTypeFilter _typeFilter = AtsTypeFilter.all;
  String? _walletFilterId;
  String? _categoryFilterId;
  bool _walletDropdownOpen = false;
  bool _categoryDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    _walletFilterId = widget.initialWalletId;
    for (final c in [_searchController, _walletDropdownSearchController, _categoryDropdownSearchController]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _walletDropdownSearchController.dispose();
    _categoryDropdownSearchController.dispose();
    super.dispose();
  }

  void _toggleWalletDropdown() {
    setState(() {
      _walletDropdownOpen = !_walletDropdownOpen;
      _categoryDropdownOpen = false;
      _walletDropdownSearchController.clear();
    });
  }

  void _toggleCategoryDropdown() {
    setState(() {
      _categoryDropdownOpen = !_categoryDropdownOpen;
      _walletDropdownOpen = false;
      _categoryDropdownSearchController.clear();
    });
  }

  void _selectWalletFilter(String? id) {
    setState(() {
      _walletFilterId = id;
      _walletDropdownOpen = false;
      _walletDropdownSearchController.clear();
    });
  }

  void _selectCategoryFilter(String? id) {
    setState(() {
      _categoryFilterId = id;
      _categoryDropdownOpen = false;
      _categoryDropdownSearchController.clear();
    });
  }

  void _editWallet(Wallet wallet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WalletSheet(existing: wallet),
    );
  }

  void _editTransaction(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionSheet(existing: transaction),
    );
  }

  List<Transaction> _applyFilters(List<Transaction> sorted, Map<String, models.Category> categoriesById, Map<String, Wallet> walletsById) {
    final query = _searchController.text.trim().toLowerCase();
    return sorted.where((t) {
      switch (_typeFilter) {
        case AtsTypeFilter.all:
          break;
        case AtsTypeFilter.expense:
          if (t.type != TransactionType.expense) return false;
        case AtsTypeFilter.income:
          if (t.type != TransactionType.income) return false;
      }
      if (_walletFilterId != null && t.walletId != _walletFilterId && t.targetWalletId != _walletFilterId) {
        return false;
      }
      if (_categoryFilterId != null && t.categoryId != _categoryFilterId) return false;
      if (query.isEmpty) return true;

      final haystack = [
        categoriesById[t.categoryId]?.name ?? '',
        t.itemName ?? '',
        t.note ?? '',
        walletsById[t.walletId]?.name ?? '',
        if (t.targetWalletId != null) walletsById[t.targetWalletId]?.name ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  List<AtsGroup> _buildGroups(List<Transaction> filtered, Map<String, models.Category> categoriesById, Map<String, Wallet> walletsById) {
    final groupsByLabel = <String, List<AtsTransactionRowData>>{};
    for (final t in filtered) {
      final isTransfer = t.type == TransactionType.transfer;
      final perspectiveWalletId = _walletFilterId ?? t.walletId;
      final isTransferIn = isTransfer && t.targetWalletId == perspectiveWalletId;
      final counterpartWallet =
          isTransfer ? walletsById[t.walletId == perspectiveWalletId ? t.targetWalletId : t.walletId] : null;

      groupsByLabel.putIfAbsent(relativeDateLabel(t.dateTime), () => []).add((
        transaction: t,
        category: categoriesById[t.categoryId],
        counterpartWallet: counterpartWallet,
        isTransferIn: isTransferIn,
        onTap: () => _editTransaction(t),
      ));
    }
    return [for (final entry in groupsByLabel.entries) (dateLabel: entry.key, items: entry.value)];
  }

  List<FilterOption> _walletOptions(List<Wallet> wallets) {
    final query = _walletDropdownSearchController.text.trim().toLowerCase();
    final all = <FilterOption>[
      (id: '', label: 'Semua Dompet', iconAsset: null, selected: _walletFilterId == null, onSelect: () => _selectWalletFilter(null)),
      for (final w in wallets)
        (id: w.id, label: w.name, iconAsset: null, selected: _walletFilterId == w.id, onSelect: () => _selectWalletFilter(w.id)),
    ];
    return query.isEmpty ? all : all.where((o) => o.label.toLowerCase().contains(query)).toList();
  }

  List<FilterOption> _categoryOptions(List<models.Category> categories) {
    final query = _categoryDropdownSearchController.text.trim().toLowerCase();
    final all = <FilterOption>[
      (id: '', label: 'Semua Kategori', iconAsset: null, selected: _categoryFilterId == null, onSelect: () => _selectCategoryFilter(null)),
      for (final c in categories)
        (
          id: c.id,
          label: c.name,
          iconAsset: AppIcons.byIconValue[c.iconValue],
          selected: _categoryFilterId == c.id,
          onSelect: () => _selectCategoryFilter(c.id),
        ),
    ];
    return query.isEmpty ? all : all.where((o) => o.label.toLowerCase().contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<FinanceRepository>();
    final wallets = repository.wallets;
    final categories = repository.categories;
    final walletsById = {for (final w in wallets) w.id: w};
    final categoriesById = {for (final c in categories) c.id: c};
    final selectedWallet = _walletFilterId == null ? null : walletsById[_walletFilterId];
    final selectedCategory = _categoryFilterId == null ? null : categoriesById[_categoryFilterId];

    final sorted = repository.transactions.toList()..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    final filtered = _applyFilters(sorted, categoriesById, walletsById);
    final netSum = filtered
        .where((t) => t.type != TransactionType.transfer)
        .fold<int>(0, (sum, t) => sum + (t.type == TransactionType.income ? t.amount : -t.amount));

    return AllTransactionsView(
      title: selectedWallet?.name ?? 'Semua Transaksi',
      showEditWallet: selectedWallet != null,
      onEditWalletTap: selectedWallet != null ? () => _editWallet(selectedWallet) : null,
      onClose: () => Navigator.of(context).pop(),
      searchController: _searchController,
      typeFilter: _typeFilter,
      onSelectTypeFilter: (f) => setState(() => _typeFilter = f),
      walletFilterLabel: selectedWallet?.name ?? 'Semua Dompet',
      walletDropdownOpen: _walletDropdownOpen,
      onToggleWalletDropdown: _toggleWalletDropdown,
      walletDropdownSearchController: _walletDropdownSearchController,
      walletOptions: _walletOptions(wallets),
      categoryFilterLabel: selectedCategory?.name ?? 'Semua Kategori',
      categoryDropdownOpen: _categoryDropdownOpen,
      onToggleCategoryDropdown: _toggleCategoryDropdown,
      categoryDropdownSearchController: _categoryDropdownSearchController,
      categoryOptions: _categoryOptions(categories),
      summaryCountText: '${filtered.length} transaksi',
      summaryNetText: '${netSum >= 0 ? '+' : '-'}${_currency.format(netSum.abs())}',
      summaryNetColor: netSum >= 0 ? AppColors.gold : AppColors.peach,
      groups: _buildGroups(filtered, categoriesById, walletsById),
    );
  }
}
