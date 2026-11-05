// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'create_income.g.dart';

@JsonSerializable()
class CreateIncome {
  const CreateIncome({
    required this.amountMinor,
    required this.onDate,
    required this.note,
    required this.estimated,
  });

  factory CreateIncome.fromJson(Map<String, Object?> json) =>
      _$CreateIncomeFromJson(json);

  final int amountMinor;
  final String onDate;
  @JsonKey(includeIfNull: true)
  final String? note;
  final bool estimated;

  Map<String, Object?> toJson() => _$CreateIncomeToJson(this);
}
