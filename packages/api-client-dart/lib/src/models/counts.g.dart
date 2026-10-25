// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'counts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Counts _$CountsFromJson(Map<String, dynamic> json) => Counts(
  envelopes: (json['envelopes'] as num).toInt(),
  allocations: (json['allocations'] as num).toInt(),
  incomes: (json['incomes'] as num).toInt(),
  expenses: (json['expenses'] as num).toInt(),
  recurringRules: (json['recurringRules'] as num).toInt(),
);

Map<String, dynamic> _$CountsToJson(Counts instance) => <String, dynamic>{
  'envelopes': instance.envelopes,
  'allocations': instance.allocations,
  'incomes': instance.incomes,
  'expenses': instance.expenses,
  'recurringRules': instance.recurringRules,
};
