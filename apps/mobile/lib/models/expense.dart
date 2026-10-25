/// A single logged expense that draws from a [Split] (envelope).
///
/// Expenses are kept even if their split/category is later removed, so past
/// periods and charts stay historically accurate.
class Expense {
  final int? id;
  final int splitId;
  final double amount;
  final DateTime date;
  final String? note;

  /// Set when this expense was auto-generated from a [RecurringRule].
  final int? recurringId;

  const Expense({
    this.id,
    required this.splitId,
    required this.amount,
    required this.date,
    this.note,
    this.recurringId,
  });

  Expense copyWith({
    int? id,
    int? splitId,
    double? amount,
    DateTime? date,
    String? note,
    int? recurringId,
  }) {
    return Expense(
      id: id ?? this.id,
      splitId: splitId ?? this.splitId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      recurringId: recurringId ?? this.recurringId,
    );
  }

  factory Expense.fromMap(Map<String, Object?> map) => Expense(
    id: map['id'] as int?,
    splitId: map['split_id'] as int,
    amount: (map['amount'] as num).toDouble(),
    date: DateTime.parse(map['date'] as String),
    note: map['note'] as String?,
    recurringId: map['recurring_id'] as int?,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'split_id': splitId,
    'amount': amount,
    'date': date.toIso8601String(),
    'note': note,
    'recurring_id': recurringId,
  };
}
