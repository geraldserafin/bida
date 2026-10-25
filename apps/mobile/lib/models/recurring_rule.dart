/// How often a [RecurringRule] repeats.
enum RecurrenceFrequency {
  weekly,
  monthly;

  factory RecurrenceFrequency.fromName(String name) =>
      RecurrenceFrequency.values.firstWhere((f) => f.name == name);
}

/// A template for recurring income or expenses (e.g. "Rent", "Salary").
///
/// Used to pre-fill new periods and to auto-generate [Expense]s.
class RecurringRule {
  final int? id;
  final int categoryId;
  final double amount;
  final RecurrenceFrequency frequency;
  final String? note;
  final bool active;

  const RecurringRule({
    this.id,
    required this.categoryId,
    required this.amount,
    required this.frequency,
    this.note,
    this.active = true,
  });

  RecurringRule copyWith({
    int? id,
    int? categoryId,
    double? amount,
    RecurrenceFrequency? frequency,
    String? note,
    bool? active,
  }) {
    return RecurringRule(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      note: note ?? this.note,
      active: active ?? this.active,
    );
  }

  factory RecurringRule.fromMap(Map<String, Object?> map) => RecurringRule(
    id: map['id'] as int?,
    categoryId: map['category_id'] as int,
    amount: (map['amount'] as num).toDouble(),
    frequency: RecurrenceFrequency.fromName(map['frequency'] as String),
    note: map['note'] as String?,
    active: (map['active'] as int) == 1,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'category_id': categoryId,
    'amount': amount,
    'frequency': frequency.name,
    'note': note,
    'active': active ? 1 : 0,
  };
}
