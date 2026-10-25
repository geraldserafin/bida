// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invalid_range.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvalidRange _$InvalidRangeFromJson(Map<String, dynamic> json) => InvalidRange(
  privateTag: InvalidRangeTag.fromJson(json['_tag'] as String),
  from: json['from'] as String,
  to: json['to'] as String,
);

Map<String, dynamic> _$InvalidRangeToJson(InvalidRange instance) =>
    <String, dynamic>{
      '_tag': _$InvalidRangeTagEnumMap[instance.privateTag]!,
      'from': instance.from,
      'to': instance.to,
    };

const _$InvalidRangeTagEnumMap = {
  InvalidRangeTag.invalidRange: 'InvalidRange',
  InvalidRangeTag.$unknown: r'$unknown',
};
