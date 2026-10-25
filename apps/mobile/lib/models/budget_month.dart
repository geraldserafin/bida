/// A stretch of days the figures are shown for — normally a calendar month, or
/// a month starting on another day when the user paid-day is not the 1st.
///
/// Both days are included. The dates are calendar days at local midnight.
class BudgetMonth {
  const BudgetMonth(this.from, this.to);

  final DateTime from;
  final DateTime to;

  /// The month that contains [day], when months start on [firstDay] (1 to 28).
  factory BudgetMonth.containing(DateTime day, {int firstDay = 1}) {
    final started = day.day >= firstDay
        ? DateTime(day.year, day.month, firstDay)
        : DateTime(day.year, day.month - 1, firstDay);
    return BudgetMonth._startingOn(started, firstDay);
  }

  factory BudgetMonth._startingOn(DateTime start, int firstDay) {
    final next = DateTime(start.year, start.month + 1, firstDay);
    return BudgetMonth(start, next.subtract(const Duration(days: 1)));
  }

  int get firstDay => from.day;

  BudgetMonth get next => BudgetMonth._startingOn(
    DateTime(from.year, from.month + 1, firstDay),
    firstDay,
  );

  BudgetMonth get previous => BudgetMonth._startingOn(
    DateTime(from.year, from.month - 1, firstDay),
    firstDay,
  );

  bool contains(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(from) && !d.isAfter(to);
  }

  /// The same month, regardless of the time of day on the dates.
  @override
  bool operator ==(Object other) =>
      other is BudgetMonth && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => 'BudgetMonth($from – $to)';
}
