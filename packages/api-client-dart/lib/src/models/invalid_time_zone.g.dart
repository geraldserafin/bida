// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invalid_time_zone.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvalidTimeZone _$InvalidTimeZoneFromJson(Map<String, dynamic> json) =>
    InvalidTimeZone(
      privateTag: InvalidTimeZoneTag.fromJson(json['_tag'] as String),
      timeZone: json['timeZone'] as String,
    );

Map<String, dynamic> _$InvalidTimeZoneToJson(InvalidTimeZone instance) =>
    <String, dynamic>{
      '_tag': _$InvalidTimeZoneTagEnumMap[instance.privateTag]!,
      'timeZone': instance.timeZone,
    };

const _$InvalidTimeZoneTagEnumMap = {
  InvalidTimeZoneTag.invalidTimeZone: 'InvalidTimeZone',
  InvalidTimeZoneTag.$unknown: r'$unknown',
};
