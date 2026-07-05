enum BudgetPeriod { monthly }

/// See doc 5.4. Optional per category (doc 4.4) — categories without a
/// Budget row simply show no progress bar.
class Budget {
  final String id;
  final String categoryId;
  final BudgetPeriod period;
  final int limitAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Budget({
    required this.id,
    required this.categoryId,
    this.period = BudgetPeriod.monthly,
    required this.limitAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  Budget copyWith({int? limitAmount, DateTime? updatedAt}) {
    return Budget(
      id: id,
      categoryId: categoryId,
      period: period,
      limitAmount: limitAmount ?? this.limitAmount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'period': period.name,
      'limit_amount': limitAmount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Budget.fromMap(Map<String, Object?> map) {
    return Budget(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      period: BudgetPeriod.values.byName(map['period'] as String),
      limitAmount: map['limit_amount'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
