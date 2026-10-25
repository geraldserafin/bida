// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetPlan _$SetPlanFromJson(Map<String, dynamic> json) => SetPlan(
  incomeMinor: (json['incomeMinor'] as num).toInt(),
  envelopes: (json['envelopes'] as List<dynamic>)
      .map((e) => EnvelopePlan.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SetPlanToJson(SetPlan instance) => <String, dynamic>{
  'incomeMinor': instance.incomeMinor,
  'envelopes': instance.envelopes,
};
