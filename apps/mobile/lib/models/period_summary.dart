import 'period.dart';

/// Aggregated totals for one period, used by the History list.
class PeriodSummary {
  final Period period;
  final double planned;
  final double spent;

  /// What was actually paid into the period (shared budgets), next to the
  /// planned income.
  final double contributed;

  const PeriodSummary({
    required this.period,
    required this.planned,
    required this.spent,
    this.contributed = 0,
  });

  double get income => period.income;
  double get remaining => planned - spent;
  double get unallocated => income - planned;
}
