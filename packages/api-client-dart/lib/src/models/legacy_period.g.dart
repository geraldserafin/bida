// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'legacy_period.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LegacyPeriod _$LegacyPeriodFromJson(Map<String, dynamic> json) => LegacyPeriod(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  startDate: json['start_date'] as String,
  endDate: json['end_date'] as String,
  income: json['income'] as num,
);

Map<String, dynamic> _$LegacyPeriodToJson(LegacyPeriod instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'start_date': instance.startDate,
      'end_date': instance.endDate,
      'income': instance.income,
    };
