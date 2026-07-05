import 'icon_type.dart';

enum CategoryType { income, expense }

/// See doc 5.3 and the household categories seeded per doc 2.7.
class Category {
  final String id;
  final String name;
  final CategoryType type;
  final String color;
  final IconType iconType;
  final String iconValue;
  final bool isSystem;

  const Category({
    required this.id,
    required this.name,
    required this.type,
    required this.color,
    required this.iconType,
    required this.iconValue,
    this.isSystem = false,
  });

  Category copyWith({
    String? name,
    String? color,
    IconType? iconType,
    String? iconValue,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      type: type,
      color: color ?? this.color,
      iconType: iconType ?? this.iconType,
      iconValue: iconValue ?? this.iconValue,
      isSystem: isSystem,
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
      'is_system': isSystem ? 1 : 0,
    };
  }

  factory Category.fromMap(Map<String, Object?> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      type: CategoryType.values.byName(map['type'] as String),
      color: map['color'] as String,
      iconType: IconType.fromName(map['icon_type'] as String),
      iconValue: map['icon_value'] as String,
      isSystem: (map['is_system'] as int) == 1,
    );
  }
}
