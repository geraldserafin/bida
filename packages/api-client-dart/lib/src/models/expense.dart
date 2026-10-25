// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'currency.dart';

part 'expense.g.dart';

@JsonSerializable()
class Expense {
  const Expense({
    required this.id,
    required this.envelopeId,
    required this.periodId,
    required this.amountMinor,
    required this.originalAmountMinor,
    required this.originalCurrency,
    required this.spentAt,
    required this.note,
    required this.recurringId,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Expense.fromJson(Map<String, Object?> json) =>
      _$ExpenseFromJson(json);

  final String id;
  final String envelopeId;
  final String periodId;
  final int amountMinor;
  @JsonKey(includeIfNull: true)
  final int? originalAmountMinor;
  @JsonKey(includeIfNull: true)
  final Currency? originalCurrency;
  final String spentAt;
  @JsonKey(includeIfNull: true)
  final String? note;
  @JsonKey(includeIfNull: true)
  final String? recurringId;
  @JsonKey(includeIfNull: true)
  final String? createdBy;
  final String createdAt;
  final String updatedAt;

  Map<String, Object?> toJson() => _$ExpenseToJson(this);
}
