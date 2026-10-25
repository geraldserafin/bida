// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'original_amount.dart';

part 'create_expense.g.dart';

@JsonSerializable()
class CreateExpense {
  const CreateExpense({
    required this.envelopeId,
    required this.amountMinor,
    required this.spentAt,
    required this.note,
    this.original,
  });

  factory CreateExpense.fromJson(Map<String, Object?> json) =>
      _$CreateExpenseFromJson(json);

  final String envelopeId;
  final int amountMinor;
  final String spentAt;
  @JsonKey(includeIfNull: true)
  final String? note;
  @JsonKey(includeIfNull: false)
  final OriginalAmount? original;

  Map<String, Object?> toJson() => _$CreateExpenseToJson(this);
}
