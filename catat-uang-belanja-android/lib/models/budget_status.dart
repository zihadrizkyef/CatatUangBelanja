import 'budget.dart';
import 'category.dart';

const _weekdayNames = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

/// A budget's current-period usage, paired with its category — computed by
/// `FinanceRepository.budgetStatuses`, shared by any screen that needs to
/// rank/display budget progress (Beranda, Rangkuman, Anggaran).
class BudgetStatus {
  const BudgetStatus({required this.category, required this.budget, required this.used, required this.pct, this.triggerCategory});

  final Category category;
  final Budget budget;
  final int used;

  /// Percentage of [budget.limitAmount] used in the current period,
  /// unclamped (can exceed 100 when over budget) — clamp at the render site
  /// if a bar needs it.
  final int pct;

  /// The income category that triggers a reset when [budget.period] is
  /// [BudgetPeriod.event]; null for other period types.
  final Category? triggerCategory;

  /// Indonesian label describing when this budget's period resets, shown on
  /// the Anggaran row (e.g. "Reset setiap tanggal 1", "Reset setiap Senin",
  /// "Reset saat pemasukan "Gaji"").
  String get resetLabel {
    switch (budget.period) {
      case BudgetPeriod.monthly:
        return 'Reset setiap tanggal ${budget.resetAnchor ?? 1}';
      case BudgetPeriod.weekly:
        final weekday = budget.resetAnchor ?? DateTime.monday;
        return 'Reset setiap ${_weekdayNames[(weekday - 1) % 7]}';
      case BudgetPeriod.event:
        return 'Reset saat pemasukan "${triggerCategory?.name ?? '-'}"';
    }
  }
}
