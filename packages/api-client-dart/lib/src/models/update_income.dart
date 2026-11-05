// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'correction.dart';

part 'update_income.g.dart';

@JsonSerializable()
class UpdateIncome {
  const UpdateIncome({
    required this.amountMinor,
    required this.onDate,
    required this.note,
    required this.estimated,
    this.correction,
  });

  factory UpdateIncome.fromJson(Map<String, Object?> json) =>
      _$UpdateIncomeFromJson(json);

  final int amountMinor;
  final String onDate;
  @JsonKey(includeIfNull: true)
  final String? note;
  final bool estimated;
  @JsonKey(includeIfNull: false)
  final Correction? correction;

  Map<String, Object?> toJson() => _$UpdateIncomeToJson(this);
}
