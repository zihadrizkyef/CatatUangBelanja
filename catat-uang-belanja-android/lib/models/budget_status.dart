import 'budget.dart';
import 'category.dart';

/// A budget's current-month usage, paired with its category — computed by
/// `FinanceRepository.budgetStatuses`, shared by any screen that needs to
/// rank/display budget progress (Beranda, Rangkuman, Anggaran).
class BudgetStatus {
  const BudgetStatus({required this.category, required this.budget, required this.used, required this.pct});

  final Category category;
  final Budget budget;
  final int used;

  /// Percentage of [budget.limitAmount] used this month, unclamped (can
  /// exceed 100 when over budget) — clamp at the render site if a bar needs it.
  final int pct;
}
