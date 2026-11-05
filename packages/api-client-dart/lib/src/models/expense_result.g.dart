// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExpenseResult _$ExpenseResultFromJson(Map<String, dynamic> json) =>
    ExpenseResult(
      expense: Expense.fromJson(json['expense'] as Map<String, dynamic>),
      transferredMinor: (json['transferredMinor'] as num).toInt(),
      raisedPlanMinor: (json['raisedPlanMinor'] as num).toInt(),
      plansExceedBalance: json['plansExceedBalance'] as bool,
    );

Map<String, dynamic> _$ExpenseResultToJson(ExpenseResult instance) =>
    <String, dynamic>{
      'expense': instance.expense,
      'transferredMinor': instance.transferredMinor,
      'raisedPlanMinor': instance.raisedPlanMinor,
      'plansExceedBalance': instance.plansExceedBalance,
    };
