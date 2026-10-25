// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invalid_import.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvalidImport _$InvalidImportFromJson(Map<String, dynamic> json) =>
    InvalidImport(
      privateTag: InvalidImportTag.fromJson(json['_tag'] as String),
      reason: json['reason'] as String,
    );

Map<String, dynamic> _$InvalidImportToJson(InvalidImport instance) =>
    <String, dynamic>{
      '_tag': _$InvalidImportTagEnumMap[instance.privateTag]!,
      'reason': instance.reason,
    };

const _$InvalidImportTagEnumMap = {
  InvalidImportTag.invalidImport: 'InvalidImport',
  InvalidImportTag.$unknown: r'$unknown',
};
