/// A budgeting period (e.g. "July 2026") with the income to be distributed.
///
/// How the income is split across categories is modelled separately as
/// [Envelope]s.
class Period {
  final String? id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final double income;

  /// ISO 4217 code. Every amount of the period is in this currency.
  final String currency;

  /// Counts the edits of the plan. It goes back to the server with an edit, so
  /// an edit made on stale data is refused.
  final int version;

  const Period({
    this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.income,
    this.currency = defaultCurrency,
    this.version = 1,
  });

  static const defaultCurrency = 'PLN';

  Period copyWith({
    String? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    double? income,
    String? currency,
    int? version,
  }) {
    return Period(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      income: income ?? this.income,
      currency: currency ?? this.currency,
      version: version ?? this.version,
    );
  }
}
