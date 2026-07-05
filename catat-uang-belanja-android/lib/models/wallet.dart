import 'icon_type.dart';

enum WalletType { cash, bank, eWallet, savings, other }

/// See doc 5.1. Balance is intentionally not a field here — it is always
/// derived from active transactions (FinanceRepository.balanceOf).
class Wallet {
  final String id;
  final String name;
  final WalletType type;
  final String color;
  final IconType iconType;
  final String iconValue;
  final bool isArchived;
  final DateTime createdAt;

  const Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.iconType,
    required this.iconValue,
    this.isArchived = false,
    required this.createdAt,
  });

  Wallet copyWith({
    String? name,
    WalletType? type,
    String? color,
    IconType? iconType,
    String? iconValue,
    bool? isArchived,
  }) {
    return Wallet(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      color: color ?? this.color,
      iconType: iconType ?? this.iconType,
      iconValue: iconValue ?? this.iconValue,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'color': color,
      'icon_type': iconType.name,
      'icon_value': iconValue,
      'is_archived': isArchived ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Wallet.fromMap(Map<String, Object?> map) {
    return Wallet(
      id: map['id'] as String,
      name: map['name'] as String,
      type: WalletType.values.byName(map['type'] as String),
      color: map['color'] as String,
      iconType: IconType.fromName(map['icon_type'] as String),
      iconValue: map['icon_value'] as String,
      isArchived: (map['is_archived'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
