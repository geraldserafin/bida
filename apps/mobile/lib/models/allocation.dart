/// Money put into an envelope ([amount] > 0) or taken back out of it (< 0).
class Allocation {
  final String? id;
  final String envelopeId;

  /// Who made it.
  final String? userId;
  final double amount;
  final DateTime madeOn;
  final String? note;

  const Allocation({
    this.id,
    required this.envelopeId,
    this.userId,
    required this.amount,
    required this.madeOn,
    this.note,
  });
}
