// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invalid_period_range_encoded.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvalidPeriodRangeEncoded _$InvalidPeriodRangeEncodedFromJson(
  Map<String, dynamic> json,
) => InvalidPeriodRangeEncoded(
  privateTag: InvalidPeriodRangeEncodedTag.fromJson(json['_tag'] as String),
  startDate: json['startDate'] as String,
  endDate: json['endDate'] as String,
);

Map<String, dynamic> _$InvalidPeriodRangeEncodedToJson(
  InvalidPeriodRangeEncoded instance,
) => <String, dynamic>{
  '_tag': _$InvalidPeriodRangeEncodedTagEnumMap[instance.privateTag]!,
  'startDate': instance.startDate,
  'endDate': instance.endDate,
};

const _$InvalidPeriodRangeEncodedTagEnumMap = {
  InvalidPeriodRangeEncodedTag.invalidPeriodRange: 'InvalidPeriodRange',
  InvalidPeriodRangeEncodedTag.$unknown: r'$unknown',
};
