// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'counts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Counts _$CountsFromJson(Map<String, dynamic> json) => Counts(
  categories: (json['categories'] as num).toInt(),
  periods: (json['periods'] as num).toInt(),
  envelopes: (json['envelopes'] as num).toInt(),
  expenses: (json['expenses'] as num).toInt(),
  recurringRules: (json['recurringRules'] as num).toInt(),
);

Map<String, dynamic> _$CountsToJson(Counts instance) => <String, dynamic>{
  'categories': instance.categories,
  'periods': instance.periods,
  'envelopes': instance.envelopes,
  'expenses': instance.expenses,
  'recurringRules': instance.recurringRules,
};
