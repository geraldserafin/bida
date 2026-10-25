// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'expense.g.dart';

@JsonSerializable()
class Expense {
  const Expense({
    required this.id,
    required this.envelopeId,
    required this.periodId,
    required this.amountMinor,
    required this.spentAt,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Expense.fromJson(Map<String, Object?> json) =>
      _$ExpenseFromJson(json);

  final String id;
  final String envelopeId;
  final String periodId;
  final int amountMinor;
  final String spentAt;
  final String? note;
  final String createdAt;
  final String updatedAt;

  Map<String, Object?> toJson() => _$ExpenseToJson(this);
}
