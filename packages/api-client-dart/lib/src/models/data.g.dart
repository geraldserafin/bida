// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Data _$DataFromJson(Map<String, dynamic> json) => Data(
  periods: (json['periods'] as List<dynamic>)
      .map((e) => Periods.fromJson(e as Map<String, dynamic>))
      .toList(),
  categories: (json['categories'] as List<dynamic>)
      .map((e) => Categories.fromJson(e as Map<String, dynamic>))
      .toList(),
  recurringRules: (json['recurring_rules'] as List<dynamic>)
      .map((e) => RecurringRules.fromJson(e as Map<String, dynamic>))
      .toList(),
  splits: (json['splits'] as List<dynamic>)
      .map((e) => Splits.fromJson(e as Map<String, dynamic>))
      .toList(),
  expenses: (json['expenses'] as List<dynamic>)
      .map((e) => Expenses.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DataToJson(Data instance) => <String, dynamic>{
  'periods': instance.periods,
  'categories': instance.categories,
  'recurring_rules': instance.recurringRules,
  'splits': instance.splits,
  'expenses': instance.expenses,
};
