import 'budget_month.dart';

/// Totals of one month, for the list of months.
class MonthSummary {
  final BudgetMonth month;
  final double income;
  final double allocated;
  final double spent;

  const MonthSummary({
    required this.month,
    required this.income,
    required this.allocated,
    required this.spent,
  });
}
