// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'legacy_expense.g.dart';

@JsonSerializable()
class LegacyExpense {
  const LegacyExpense({
    required this.id,
    required this.splitId,
    required this.amount,
    required this.date,
    required this.note,
    required this.recurringId,
  });

  factory LegacyExpense.fromJson(Map<String, Object?> json) =>
      _$LegacyExpenseFromJson(json);

  final int id;
  @JsonKey(name: 'split_id')
  final int splitId;
  final num amount;
  final String date;
  final String? note;
  @JsonKey(name: 'recurring_id')
  final int? recurringId;

  Map<String, Object?> toJson() => _$LegacyExpenseToJson(this);
}
