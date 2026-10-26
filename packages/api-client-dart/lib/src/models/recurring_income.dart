// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'recurring_income.g.dart';

@JsonSerializable()
class RecurringIncome {
  const RecurringIncome({
    required this.id,
    required this.userId,
    required this.amountMinor,
    required this.dayOfMonth,
    required this.note,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RecurringIncome.fromJson(Map<String, Object?> json) =>
      _$RecurringIncomeFromJson(json);

  final String id;
  final String userId;
  final int amountMinor;
  final int dayOfMonth;
  @JsonKey(includeIfNull: true)
  final String? note;
  final bool active;
  final String createdAt;
  final String updatedAt;

  Map<String, Object?> toJson() => _$RecurringIncomeToJson(this);
}
