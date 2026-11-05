// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'duplicate_envelope_name.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DuplicateEnvelopeName _$DuplicateEnvelopeNameFromJson(
  Map<String, dynamic> json,
) => DuplicateEnvelopeName(
  privateTag: DuplicateEnvelopeNameTag.fromJson(json['_tag'] as String),
  name: json['name'] as String,
);

Map<String, dynamic> _$DuplicateEnvelopeNameToJson(
  DuplicateEnvelopeName instance,
) => <String, dynamic>{
  '_tag': _$DuplicateEnvelopeNameTagEnumMap[instance.privateTag]!,
  'name': instance.name,
};

const _$DuplicateEnvelopeNameTagEnumMap = {
  DuplicateEnvelopeNameTag.duplicateEnvelopeName: 'DuplicateEnvelopeName',
  DuplicateEnvelopeNameTag.$unknown: r'$unknown',
};
