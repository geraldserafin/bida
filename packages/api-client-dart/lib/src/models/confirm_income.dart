// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'correction.dart';

part 'confirm_income.g.dart';

@JsonSerializable()
class ConfirmIncome {
  const ConfirmIncome({required this.amountMinor, this.correction});

  factory ConfirmIncome.fromJson(Map<String, Object?> json) =>
      _$ConfirmIncomeFromJson(json);

  final int amountMinor;
  @JsonKey(includeIfNull: false)
  final Correction? correction;

  Map<String, Object?> toJson() => _$ConfirmIncomeToJson(this);
}
