// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invalid_csv_encoded.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvalidCsvEncoded _$InvalidCsvEncodedFromJson(Map<String, dynamic> json) =>
    InvalidCsvEncoded(
      privateTag: InvalidCsvEncodedTag.fromJson(json['_tag'] as String),
      line: (json['line'] as num).toInt(),
      reason: json['reason'] as String,
    );

Map<String, dynamic> _$InvalidCsvEncodedToJson(InvalidCsvEncoded instance) =>
    <String, dynamic>{
      '_tag': _$InvalidCsvEncodedTagEnumMap[instance.privateTag]!,
      'line': instance.line,
      'reason': instance.reason,
    };

const _$InvalidCsvEncodedTagEnumMap = {
  InvalidCsvEncodedTag.invalidCsv: 'InvalidCsv',
  InvalidCsvEncodedTag.$unknown: r'$unknown',
};
