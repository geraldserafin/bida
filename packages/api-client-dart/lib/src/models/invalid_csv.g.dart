// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invalid_csv.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvalidCsv _$InvalidCsvFromJson(Map<String, dynamic> json) => InvalidCsv(
  privateTag: InvalidCsvTag.fromJson(json['_tag'] as String),
  line: (json['line'] as num).toInt(),
  reason: json['reason'] as String,
);

Map<String, dynamic> _$InvalidCsvToJson(InvalidCsv instance) =>
    <String, dynamic>{
      '_tag': _$InvalidCsvTagEnumMap[instance.privateTag]!,
      'line': instance.line,
      'reason': instance.reason,
    };

const _$InvalidCsvTagEnumMap = {
  InvalidCsvTag.invalidCsv: 'InvalidCsv',
  InvalidCsvTag.$unknown: r'$unknown',
};
