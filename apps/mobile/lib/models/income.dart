/// Money that came in, e.g. a salary. The only way money enters the app.
class Income {
  final String? id;
  final double amount;
  final DateTime receivedOn;
  final String? note;

  const Income({
    this.id,
    required this.amount,
    required this.receivedOn,
    this.note,
  });
}
