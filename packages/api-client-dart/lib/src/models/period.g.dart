// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'period.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Period _$PeriodFromJson(Map<String, dynamic> json) => Period(
  id: json['id'] as String,
  name: json['name'] as String,
  startDate: json['startDate'] as String,
  endDate: json['endDate'] as String,
  incomeMinor: (json['incomeMinor'] as num).toInt(),
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
);

Map<String, dynamic> _$PeriodToJson(Period instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'startDate': instance.startDate,
  'endDate': instance.endDate,
  'incomeMinor': instance.incomeMinor,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};
