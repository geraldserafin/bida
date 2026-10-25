// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invalid_import_encoded.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvalidImportEncoded _$InvalidImportEncodedFromJson(
  Map<String, dynamic> json,
) => InvalidImportEncoded(
  privateTag: InvalidImportEncodedTag.fromJson(json['_tag'] as String),
  reason: json['reason'] as String,
);

Map<String, dynamic> _$InvalidImportEncodedToJson(
  InvalidImportEncoded instance,
) => <String, dynamic>{
  '_tag': _$InvalidImportEncodedTagEnumMap[instance.privateTag]!,
  'reason': instance.reason,
};

const _$InvalidImportEncodedTagEnumMap = {
  InvalidImportEncodedTag.invalidImport: 'InvalidImport',
  InvalidImportEncodedTag.$unknown: r'$unknown',
};
