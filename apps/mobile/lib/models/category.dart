/// A reusable spending category — e.g. Rent, Food, Savings.
///
/// Categories live independently of periods so they can be reused every month.
class Category {
  final String? id;
  final String name;

  /// Hex color string (e.g. `#66BB6A`) used in charts and chips.
  final String color;

  /// Optional icon key (see `categoryIcons`).
  final String? icon;

  const Category({this.id, required this.name, required this.color, this.icon});

  Category copyWith({String? id, String? name, String? color, String? icon}) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }
}
