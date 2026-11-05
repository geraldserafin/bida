// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'expense.dart';

part 'expense_result.g.dart';

@JsonSerializable()
class ExpenseResult {
  const ExpenseResult({
    required this.expense,
    required this.transferredMinor,
    required this.raisedPlanMinor,
    required this.plansExceedBalance,
  });

  factory ExpenseResult.fromJson(Map<String, Object?> json) =>
      _$ExpenseResultFromJson(json);

  final Expense expense;
  final int transferredMinor;
  final int raisedPlanMinor;
  final bool plansExceedBalance;

  Map<String, Object?> toJson() => _$ExpenseResultToJson(this);
}
