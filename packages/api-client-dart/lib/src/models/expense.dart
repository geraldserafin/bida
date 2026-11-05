// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'for_whom.dart';

part 'expense.g.dart';

@JsonSerializable()
class Expense {
  const Expense({
    required this.id,
    required this.householdId,
    required this.periodId,
    required this.envelopeId,
    required this.createdBy,
    required this.authorName,
    required this.amountMinor,
    required this.spentAt,
    required this.title,
    required this.forWhom,
    required this.forWhomUserId,
    required this.forWhomName,
    required this.estimated,
    required this.ruleId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Expense.fromJson(Map<String, Object?> json) =>
      _$ExpenseFromJson(json);

  final String id;
  final String householdId;
  final String periodId;
  final String envelopeId;
  @JsonKey(includeIfNull: true)
  final String? createdBy;
  final String authorName;
  final int amountMinor;
  final String spentAt;
  @JsonKey(includeIfNull: true)
  final String? title;
  @JsonKey(includeIfNull: true)
  final ForWhom? forWhom;
  @JsonKey(includeIfNull: true)
  final String? forWhomUserId;
  @JsonKey(includeIfNull: true)
  final String? forWhomName;
  final bool estimated;
  @JsonKey(includeIfNull: true)
  final String? ruleId;
  final String createdAt;
  final String updatedAt;

  Map<String, Object?> toJson() => _$ExpenseToJson(this);
}
