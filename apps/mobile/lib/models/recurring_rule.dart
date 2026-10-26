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

/// Money that comes in every month, e.g. a salary. Applying the rules to a
/// month adds an income for it, on [dayOfMonth].
class RecurringIncome {
  final String? id;
  final double amount;

  /// 1 to 28.
  final int dayOfMonth;
  final String? note;
  final bool active;

  const RecurringIncome({
    this.id,
    required this.amount,
    required this.dayOfMonth,
    this.note,
    this.active = true,
  });
}

/// A sum that goes into an envelope every month. Applying the rules to a month
/// puts it there, on [dayOfMonth].
class AllocationRule {
  final String? id;
  final String envelopeId;
  final double amount;

  /// 1 to 28.
  final int dayOfMonth;
  final String? note;
  final bool active;

  const AllocationRule({
    this.id,
    required this.envelopeId,
    required this.amount,
    required this.dayOfMonth,
    this.note,
    this.active = true,
  });
}

/// How many entries applying the recurring rules adds, or would add.
class ApplyOutcome {
  final int incomes;
  final int allocations;
  final int expenses;

  /// Allocations that could not be made because the envelope did not have the
  /// money. Always 0 for what would be added.
  final int skipped;

  const ApplyOutcome({
    this.incomes = 0,
    this.allocations = 0,
    this.expenses = 0,
    this.skipped = 0,
  });

  /// How many entries were, or would be, added.
  int get added => incomes + allocations + expenses;

  bool get isEmpty => added == 0 && skipped == 0;
}
