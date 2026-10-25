import 'period.dart';

/// Aggregated totals for one period, used by the History list.
class PeriodSummary {
  final Period period;
  final double planned;
  final double spent;

  const PeriodSummary({
    required this.period,
    required this.planned,
    required this.spent,
  });

  double get income => period.income;
  double get remaining => planned - spent;
  double get unallocated => income - planned;
}
