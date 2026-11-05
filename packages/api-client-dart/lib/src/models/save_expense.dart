// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'decision.dart';
import 'for_whom.dart';

part 'save_expense.g.dart';

@JsonSerializable()
class SaveExpense {
  const SaveExpense({
    required this.envelopeId,
    required this.amountMinor,
    required this.spentAt,
    required this.title,
    required this.forWhom,
    required this.forWhomUserId,
    this.decision,
  });

  factory SaveExpense.fromJson(Map<String, Object?> json) =>
      _$SaveExpenseFromJson(json);

  final String envelopeId;
  final int amountMinor;
  final String spentAt;
  @JsonKey(includeIfNull: true)
  final String? title;
  @JsonKey(includeIfNull: true)
  final ForWhom? forWhom;
  @JsonKey(includeIfNull: true)
  final String? forWhomUserId;
  @JsonKey(includeIfNull: false)
  final Decision? decision;

  Map<String, Object?> toJson() => _$SaveExpenseToJson(this);
}
