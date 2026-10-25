// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invalid_period_range.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvalidPeriodRange _$InvalidPeriodRangeFromJson(Map<String, dynamic> json) =>
    InvalidPeriodRange(
      privateTag: InvalidPeriodRangeTag.fromJson(json['_tag'] as String),
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
    );

Map<String, dynamic> _$InvalidPeriodRangeToJson(InvalidPeriodRange instance) =>
    <String, dynamic>{
      '_tag': _$InvalidPeriodRangeTagEnumMap[instance.privateTag]!,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
    };

const _$InvalidPeriodRangeTagEnumMap = {
  InvalidPeriodRangeTag.invalidPeriodRange: 'InvalidPeriodRange',
  InvalidPeriodRangeTag.$unknown: r'$unknown',
};
