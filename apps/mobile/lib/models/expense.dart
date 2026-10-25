/// A single logged expense that draws from an [Envelope].
class Expense {
  final String? id;
  final String envelopeId;

  /// In the currency of the period; this is what counts against the envelope.
  final double amount;
  final DateTime date;
  final String? note;

  /// Set when the expense was generated from a recurring rule.
  final String? recurringId;

  /// What was actually paid when it was in another currency than the
  /// period's. Both are null for an ordinary expense.
  final double? originalAmount;
  final String? originalCurrency;

  /// Who added it (a user id), null for imported data and for people whose
  /// account is gone.
  final String? createdBy;

  const Expense({
    this.id,
    required this.envelopeId,
    required this.amount,
    required this.date,
    this.note,
    this.recurringId,
    this.originalAmount,
    this.originalCurrency,
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
      originalAmount: originalAmount,
      originalCurrency: originalCurrency,
      createdBy: createdBy,
    );
  }
}
