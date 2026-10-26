import 'package:intl/intl.dart';

/// Formats amounts as Polish złoty, e.g. `1 234,56 zł`.
///
/// Centralised so every screen shows money the same way. `pl_PL` gives the
/// space thousands separator and comma decimal separator Polish users expect.
final NumberFormat _plZloty = NumberFormat.currency(
  locale: 'pl_PL',
  symbol: 'zł',
  decimalDigits: 2,
);

String formatZloty(num amount) => _plZloty.format(amount);

final NumberFormat _plPlain = NumberFormat.decimalPatternDigits(
  locale: 'pl_PL',
  decimalDigits: 2,
);

/// An amount without the currency, e.g. `1 234,56`: the first half of
/// "spent / planned", or the value of an amount field.
String formatPlain(num amount) => _plPlain.format(amount);
