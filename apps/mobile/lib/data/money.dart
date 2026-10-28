/// The API sends amounts in grosze; the app shows and edits złoty.
double fromMinor(int minor) => minor / 100;

/// Rounds, because `12.34 * 100` is `1233.9999999999998` in floating point.
int toMinor(double amount) => (amount * 100).round();
