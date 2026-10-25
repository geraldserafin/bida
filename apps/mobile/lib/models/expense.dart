/// A single logged expense that draws from an [Envelope].
class Expense {
  final String? id;
  final String envelopeId;
  final double amount;
  final DateTime date;
  final String? note;

  /// Set when the expense was generated from a recurring rule.
  final String? recurringId;

  /// Who recorded it.
  final String? createdBy;

  const Expense({
    this.id,
    required this.envelopeId,
    required this.amount,
    required this.date,
    this.note,
    this.recurringId,
    this.createdBy,
  });

  Expense copyWith({
    String? id,
    String? envelopeId,
    double? amount,
    DateTime? date,
    String? note,
    String? recurringId,
  }) {
    return Expense(
      id: id ?? this.id,
      envelopeId: envelopeId ?? this.envelopeId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      recurringId: recurringId ?? this.recurringId,
      createdBy: createdBy,
    );
  }
}
