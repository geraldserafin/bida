// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'save_recurring_income.g.dart';

@JsonSerializable()
class SaveRecurringIncome {
  const SaveRecurringIncome({
    required this.amountMinor,
    required this.dayOfMonth,
    required this.note,
    required this.active,
  });

  factory SaveRecurringIncome.fromJson(Map<String, Object?> json) =>
      _$SaveRecurringIncomeFromJson(json);

  final int amountMinor;
  final int dayOfMonth;
  @JsonKey(includeIfNull: true)
  final String? note;
  final bool active;

  Map<String, Object?> toJson() => _$SaveRecurringIncomeToJson(this);
}
