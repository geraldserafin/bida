/// The part of a period's income planned for one category.
///
/// Each envelope is a virtual pot you fill at the start of the period and
/// draw from as you spend. A category has at most one envelope per period.
class Envelope {
  final String? id;
  final String periodId;
  final String categoryId;

  /// Planned amount, in the currency of the period.
  final double plannedAmount;

  const Envelope({
    this.id,
    required this.periodId,
    required this.categoryId,
    required this.plannedAmount,
  });

  Envelope copyWith({
    String? id,
    String? periodId,
    String? categoryId,
    double? plannedAmount,
  }) {
    return Envelope(
      id: id ?? this.id,
      periodId: periodId ?? this.periodId,
      categoryId: categoryId ?? this.categoryId,
      plannedAmount: plannedAmount ?? this.plannedAmount,
    );
  }
}
