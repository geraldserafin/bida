/// A household ("gospodarstwo"): the budget everything else belongs to. The
/// API calls it a space. Sharing it with other people is still to come, so
/// for now everyone has their own.
class Household {
  final String id;
  final String name;

  /// ISO 4217 code of new periods and recurring rules.
  final String currency;

  const Household({
    required this.id,
    required this.name,
    required this.currency,
  });
}
