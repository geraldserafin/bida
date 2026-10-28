import 'budget_month.dart';
import 'envelope_progress.dart';

/// The state of the user's money over a month.
class Overview {
  final BudgetMonth month;

  /// Income received in the month.
  final double income;

  /// What the user put into top-level envelopes in the month, net.
  final double allocated;

  /// What the user spent in the month.
  final double spent;

  /// Not yet put into an envelope, at the end of the month. Can be negative.
  final double pool;

  final List<EnvelopeProgress> envelopes;

  const Overview({
    required this.month,
    required this.income,
    required this.allocated,
    required this.spent,
    required this.pool,
    required this.envelopes,
  });

  static Overview empty(BudgetMonth month) => Overview(
    month: month,
    income: 0,
    allocated: 0,
    spent: 0,
    pool: 0,
    envelopes: const [],
  );
}
