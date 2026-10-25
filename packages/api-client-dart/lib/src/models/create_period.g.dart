// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_period.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreatePeriod _$CreatePeriodFromJson(Map<String, dynamic> json) => CreatePeriod(
  name: json['name'] as String,
  startDate: json['startDate'] as String,
  endDate: json['endDate'] as String,
  incomeMinor: (json['incomeMinor'] as num).toInt(),
  envelopes: (json['envelopes'] as List<dynamic>)
      .map((e) => EnvelopePlan.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$CreatePeriodToJson(CreatePeriod instance) =>
    <String, dynamic>{
      'name': instance.name,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
      'incomeMinor': instance.incomeMinor,
      'envelopes': instance.envelopes,
    };
