// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'correction.dart';

part 'remove_income.g.dart';

@JsonSerializable()
class RemoveIncome {
  const RemoveIncome({this.correction});

  factory RemoveIncome.fromJson(Map<String, Object?> json) =>
      _$RemoveIncomeFromJson(json);

  @JsonKey(includeIfNull: false)
  final Correction? correction;

  Map<String, Object?> toJson() => _$RemoveIncomeToJson(this);
}
