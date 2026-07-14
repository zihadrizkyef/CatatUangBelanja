import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/icon_type.dart';
import '../models/wallet.dart';
import '../repositories/finance_repository.dart';
import '../theme/app_icons.dart';
import 'wallet_sheet_view.dart';

/// Maps an icon choice to its [WalletType], since the sheet has no separate
/// type picker — mirrors how [AppIcons.categoryIconColors] ties an icon
/// choice to a color without a separate color picker.
const _walletTypeByIconValue = {
  'wallet_cash': WalletType.cash,
  'wallet_bank': WalletType.bank,
  'wallet_ewallet': WalletType.eWallet,
};

/// Add/edit bottom sheet container for a single wallet: name field + the
/// icon-grid picker. Reads [FinanceRepository] and wires up the sheet's
/// [Navigator] dismissal; hands the rest to [WalletSheetView].
///
/// Note: unlike the mockup, there is no "Saldo" input — [Wallet] balances
/// are always derived from transactions (doc 4.2), never stored, so an
/// initial/edited balance has nowhere to be written.
class WalletSheet extends StatefulWidget {
  const WalletSheet({super.key, this.existing});

  final Wallet? existing;

  @override
  State<WalletSheet> createState() => _WalletSheetState();
}

class _WalletSheetState extends State<WalletSheet> {
  late final TextEditingController _nameController;
  late String _iconValue;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _iconValue = widget.existing?.iconValue ?? AppIcons.walletIconChoices.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final repository = context.read<FinanceRepository>();
    final color = AppIcons.walletIconColors[_iconValue] ?? '#F3ECE6';
    final type = _walletTypeByIconValue[_iconValue] ?? WalletType.other;
    if (_isEdit) {
      await repository.updateWallet(widget.existing!.copyWith(name: name, iconValue: _iconValue, color: color, type: type));
    } else {
      await repository.addWallet(Wallet(
        id: const Uuid().v4(),
        name: name,
        type: type,
        color: color,
        iconType: IconType.system,
        iconValue: _iconValue,
        createdAt: DateTime.now(),
      ));
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final repository = context.read<FinanceRepository>();
    if (repository.wallets.where((w) => !w.isArchived).length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal harus ada 1 dompet, Bun'), duration: Duration(milliseconds: 1800)),
      );
      return;
    }
    await repository.deleteWallet(existing.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return WalletSheetView(
      isEdit: _isEdit,
      nameController: _nameController,
      selectedIconValue: _iconValue,
      onSelectIcon: (value) => setState(() => _iconValue = value),
      onSave: _save,
      onClose: () => Navigator.of(context).pop(),
      onDelete: _isEdit ? _delete : null,
    );
  }
}
