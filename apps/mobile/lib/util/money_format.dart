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
