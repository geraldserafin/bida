/// A pot of money — e.g. Rent, Food, Savings.
///
/// Envelopes are either top-level or the sub-envelope of a top-level one
/// ([parentId]); there is nothing deeper. Money is put in, spent from, and the
/// balance rolls over from month to month.
class Envelope {
  final String? id;

  /// The top-level envelope this one is part of, or null for a top-level one.
  final String? parentId;
  final String name;

  /// Hex color string (e.g. `#66BB6A`) used in charts and chips.
  final String color;

  /// Optional icon key (see `envelopeIcons`).
  final String? icon;

  const Envelope({
    this.id,
    this.parentId,
    required this.name,
    required this.color,
    this.icon,
  });

  bool get isTopLevel => parentId == null;

  Envelope copyWith({
    String? id,
    String? parentId,
    String? name,
    String? color,
    String? icon,
  }) {
    return Envelope(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }
}
