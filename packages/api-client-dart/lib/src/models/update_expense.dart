// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'update_expense.g.dart';

@JsonSerializable()
class UpdateExpense {
  const UpdateExpense({
    required this.envelopeId,
    required this.amountMinor,
    required this.spentAt,
    required this.note,
  });

  factory UpdateExpense.fromJson(Map<String, Object?> json) =>
      _$UpdateExpenseFromJson(json);

  final String envelopeId;
  final int amountMinor;
  final String spentAt;
  @JsonKey(includeIfNull: true)
  final String? note;

  Map<String, Object?> toJson() => _$UpdateExpenseToJson(this);
}
