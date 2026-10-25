// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'legacy_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LegacyData _$LegacyDataFromJson(Map<String, dynamic> json) => LegacyData(
  periods: (json['periods'] as List<dynamic>)
      .map((e) => LegacyPeriod.fromJson(e as Map<String, dynamic>))
      .toList(),
  categories: (json['categories'] as List<dynamic>)
      .map((e) => LegacyCategory.fromJson(e as Map<String, dynamic>))
      .toList(),
  recurringRules: (json['recurring_rules'] as List<dynamic>)
      .map((e) => LegacyRecurringRule.fromJson(e as Map<String, dynamic>))
      .toList(),
  splits: (json['splits'] as List<dynamic>)
      .map((e) => LegacySplit.fromJson(e as Map<String, dynamic>))
      .toList(),
  expenses: (json['expenses'] as List<dynamic>)
      .map((e) => LegacyExpense.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$LegacyDataToJson(LegacyData instance) =>
    <String, dynamic>{
      'periods': instance.periods,
      'categories': instance.categories,
      'recurring_rules': instance.recurringRules,
      'splits': instance.splits,
      'expenses': instance.expenses,
    };
