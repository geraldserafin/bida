// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_period.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdatePeriod _$UpdatePeriodFromJson(Map<String, dynamic> json) => UpdatePeriod(
  version: (json['version'] as num).toInt(),
  name: json['name'] as String,
  startDate: json['startDate'] as String,
  endDate: json['endDate'] as String,
);

Map<String, dynamic> _$UpdatePeriodToJson(UpdatePeriod instance) =>
    <String, dynamic>{
      'version': instance.version,
      'name': instance.name,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
    };
