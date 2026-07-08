import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/budget_status.dart';
import '../repositories/finance_repository.dart';
import 'budget_sheet.dart';
import 'budget_view.dart';

/// Full-screen budget CRUD container (was AnggaranScreen in the mockup) —
/// pushed via [Navigator] from the "Kelola" links on Beranda/Rangkuman and
/// Pengaturan's "Kategori & Anggaran" row. Reads [FinanceRepository] and
/// wires up the add/edit [BudgetSheet]; hands the rest to [BudgetView].
class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  void _openSheet({BudgetStatus? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BudgetSheet(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repository = context.watch<FinanceRepository>();

    return BudgetView(
      budgetStatuses: repository.budgetStatuses,
      onTapRow: (status) => _openSheet(existing: status),
      onTapAdd: _openSheet,
      onTapBack: () => Navigator.of(context).pop(),
    );
  }
}
