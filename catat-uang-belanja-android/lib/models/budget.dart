enum BudgetPeriod { monthly, weekly, event }

/// See doc 5.4. Optional per category (doc 4.4) — categories without a
/// Budget row simply show no progress bar.
///
/// [resetAnchor] holds the day-of-month (1-31) when [period] is monthly, or
/// the day-of-week ([DateTime.monday]..[DateTime.sunday]) when weekly; null
/// when [period] is event. [triggerCategoryId] holds the income category
/// whose transactions reset the period when [period] is event; null
/// otherwise. [currentPeriodStartedAt] marks the start of the active period
/// — advanced by `FinanceRepository` on calendar reset, on a matching
/// event-trigger transaction, or manually via the reset button; usage is
/// always computed on demand from transactions on/after this timestamp,
/// never stored (see [FinanceRepository.budgetUsage]).
class Budget {
  final String id;
  final String categoryId;
  final BudgetPeriod period;
  final int? resetAnchor;
  final String? triggerCategoryId;
  final int limitAmount;
  final DateTime currentPeriodStartedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Budget({
    required this.id,
    required this.categoryId,
    this.period = BudgetPeriod.monthly,
    this.resetAnchor,
    this.triggerCategoryId,
    required this.limitAmount,
    DateTime? currentPeriodStartedAt,
    required this.createdAt,
    required this.updatedAt,
  }) : currentPeriodStartedAt = currentPeriodStartedAt ?? createdAt;

  Budget copyWith({int? limitAmount, DateTime? currentPeriodStartedAt, DateTime? updatedAt}) {
    return Budget(
      id: id,
      categoryId: categoryId,
      period: period,
      resetAnchor: resetAnchor,
      triggerCategoryId: triggerCategoryId,
      limitAmount: limitAmount ?? this.limitAmount,
      currentPeriodStartedAt: currentPeriodStartedAt ?? this.currentPeriodStartedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'period': period.name,
      'reset_anchor': resetAnchor,
      'trigger_category_id': triggerCategoryId,
      'limit_amount': limitAmount,
      'current_period_started_at': currentPeriodStartedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Budget.fromMap(Map<String, Object?> map) {
    return Budget(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      period: BudgetPeriod.values.byName(map['period'] as String),
      resetAnchor: map['reset_anchor'] as int?,
      triggerCategoryId: map['trigger_category_id'] as String?,
      limitAmount: map['limit_amount'] as int,
      currentPeriodStartedAt: DateTime.parse(map['current_period_started_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
