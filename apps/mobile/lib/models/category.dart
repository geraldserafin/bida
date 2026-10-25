/// A reusable spending category (envelope) — e.g. Rent, Food, Savings.
///
/// Categories live independently of periods so they can be reused every month.
class Category {
  final int? id;
  final String name;

  /// Hex color string (e.g. `#4CAF50`) used to keep charts consistent.
  final String color;

  /// Optional icon key, resolved to a [IconData] in the UI layer.
  final String? icon;

  const Category({this.id, required this.name, required this.color, this.icon});

  Category copyWith({int? id, String? name, String? color, String? icon}) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }

  factory Category.fromMap(Map<String, Object?> map) => Category(
    id: map['id'] as int?,
    name: map['name'] as String,
    color: map['color'] as String,
    icon: map['icon'] as String?,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'color': color,
    'icon': icon,
  };
}
