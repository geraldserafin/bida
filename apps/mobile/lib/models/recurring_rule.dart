enum RecurrenceFrequency { weekly, monthly }

/// An expense that repeats, e.g. rent. Applying the rules to a month adds one
/// expense for each.
class RecurringRule {
  final String? id;
  final String envelopeId;
  final double amount;
  final RecurrenceFrequency frequency;
  final String? note;
  final bool active;

  const RecurringRule({
    this.id,
    required this.envelopeId,
    required this.amount,
    required this.frequency,
    this.note,
    this.active = true,
  });

  RecurringRule copyWith({
    String? id,
    String? envelopeId,
    double? amount,
    RecurrenceFrequency? frequency,
    String? note,
    bool? active,
  }) {
    return RecurringRule(
      id: id ?? this.id,
      envelopeId: envelopeId ?? this.envelopeId,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      note: note ?? this.note,
      active: active ?? this.active,
    );
  }
}
