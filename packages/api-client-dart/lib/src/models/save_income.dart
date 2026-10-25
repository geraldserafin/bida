// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'save_income.g.dart';

@JsonSerializable()
class SaveIncome {
  const SaveIncome({
    required this.amountMinor,
    required this.receivedOn,
    required this.note,
  });

  factory SaveIncome.fromJson(Map<String, Object?> json) =>
      _$SaveIncomeFromJson(json);

  final int amountMinor;
  final String receivedOn;
  @JsonKey(includeIfNull: true)
  final String? note;

  Map<String, Object?> toJson() => _$SaveIncomeToJson(this);
}
