// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'envelope_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnvelopePlan _$EnvelopePlanFromJson(Map<String, dynamic> json) => EnvelopePlan(
  categoryId: json['categoryId'] as String,
  plannedMinor: (json['plannedMinor'] as num).toInt(),
);

Map<String, dynamic> _$EnvelopePlanToJson(EnvelopePlan instance) =>
    <String, dynamic>{
      'categoryId': instance.categoryId,
      'plannedMinor': instance.plannedMinor,
    };
