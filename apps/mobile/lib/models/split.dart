/// The "plan": how much of a [Period]'s income is allocated to a [Category].
///
/// Each split is a virtual envelope you fill at the start of the period and
/// draw from as you log expenses against it.
class Split {
  final int? id;
  final int periodId;
  final int categoryId;
  final double plannedAmount;

  const Split({
    this.id,
    required this.periodId,
    required this.categoryId,
    required this.plannedAmount,
  });

  Split copyWith({
    int? id,
    int? periodId,
    int? categoryId,
    double? plannedAmount,
  }) {
    return Split(
      id: id ?? this.id,
      periodId: periodId ?? this.periodId,
      categoryId: categoryId ?? this.categoryId,
      plannedAmount: plannedAmount ?? this.plannedAmount,
    );
  }

  factory Split.fromMap(Map<String, Object?> map) => Split(
    id: map['id'] as int?,
    periodId: map['period_id'] as int,
    categoryId: map['category_id'] as int,
    plannedAmount: (map['planned_amount'] as num).toDouble(),
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'period_id': periodId,
    'category_id': categoryId,
    'planned_amount': plannedAmount,
  };
}
