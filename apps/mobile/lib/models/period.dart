/// A single planning period, e.g. "July 2026".
///
/// Holds the total [income] for the period; how that income is divided across
/// categories is modelled separately as [Split]s.
class Period {
  final int? id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final double income;

  const Period({
    this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.income,
  });

  Period copyWith({
    int? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    double? income,
  }) {
    return Period(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      income: income ?? this.income,
    );
  }

  factory Period.fromMap(Map<String, Object?> map) => Period(
    id: map['id'] as int?,
    name: map['name'] as String,
    startDate: DateTime.parse(map['start_date'] as String),
    endDate: DateTime.parse(map['end_date'] as String),
    income: (map['income'] as num).toDouble(),
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'start_date': startDate.toIso8601String(),
    'end_date': endDate.toIso8601String(),
    'income': income,
  };
}
