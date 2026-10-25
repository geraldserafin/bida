import 'period.dart';

enum RecurrenceFrequency { weekly, monthly }

/// An expense that repeats, e.g. rent. Applying the rule to a period adds one
/// expense for it.
class RecurringRule {
  final String? id;
  final String categoryId;
  final double amount;

  /// ISO 4217 code. The rule only applies to periods in this currency.
  final String currency;
  final RecurrenceFrequency frequency;
  final String? note;
  final bool active;

  const RecurringRule({
    this.id,
    required this.categoryId,
    required this.amount,
    this.currency = Period.defaultCurrency,
    required this.frequency,
    this.note,
    this.active = true,
  });

  RecurringRule copyWith({
    String? id,
    String? categoryId,
    double? amount,
    String? currency,
    RecurrenceFrequency? frequency,
    String? note,
    bool? active,
  }) {
    return RecurringRule(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      frequency: frequency ?? this.frequency,
      note: note ?? this.note,
      active: active ?? this.active,
    );
  }
}
