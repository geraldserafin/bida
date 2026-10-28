// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'apply_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApplyResult _$ApplyResultFromJson(Map<String, dynamic> json) => ApplyResult(
  incomes: (json['incomes'] as num).toInt(),
  allocations: (json['allocations'] as num).toInt(),
  expenses: (json['expenses'] as num).toInt(),
  skipped: (json['skipped'] as num).toInt(),
);

Map<String, dynamic> _$ApplyResultToJson(ApplyResult instance) =>
    <String, dynamic>{
      'incomes': instance.incomes,
      'allocations': instance.allocations,
      'expenses': instance.expenses,
      'skipped': instance.skipped,
    };
