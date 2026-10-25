import 'dart:math';

/// Decimal places of the minor unit of each supported currency (12.34 PLN is
/// 1234, 500 JPY is 500). Mirrors `CURRENCY_EXPONENTS` in the API contract.
const _exponents = <String, int>{
  'PLN': 2,
  'EUR': 2,
  'USD': 2,
  'GBP': 2,
  'CHF': 2,
  'CZK': 2,
  'SEK': 2,
  'NOK': 2,
  'DKK': 2,
  'HUF': 2,
  'JPY': 0,
};

int exponentOf(String currency) => _exponents[currency] ?? 2;

/// The API sends amounts in minor units; the app shows and edits whole units.
double fromMinor(int minor, String currency) =>
    minor / pow(10, exponentOf(currency));

/// Rounds, because `12.34 * 100` is `1233.9999999999998` in floating point.
int toMinor(double amount, String currency) =>
    (amount * pow(10, exponentOf(currency))).round();
