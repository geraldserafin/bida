/// A user-typed amount, with a comma or a dot as the decimal separator.
/// Null when it is not a number.
double? parseAmount(String text) {
  final normalized = text.trim().replaceAll(',', '.');
  if (normalized.isEmpty) return null;
  return double.tryParse(normalized);
}

/// An amount as it is edited: no trailing `.0`, a comma for the decimals.
String amountText(double value) {
  final text = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();
  return text.replaceAll('.', ',');
}
