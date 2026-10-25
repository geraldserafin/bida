// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'envelope_not_found.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnvelopeNotFound _$EnvelopeNotFoundFromJson(Map<String, dynamic> json) =>
    EnvelopeNotFound(
      privateTag: EnvelopeNotFoundTag.fromJson(json['_tag'] as String),
      id: json['id'] as String,
    );

Map<String, dynamic> _$EnvelopeNotFoundToJson(EnvelopeNotFound instance) =>
    <String, dynamic>{
      '_tag': _$EnvelopeNotFoundTagEnumMap[instance.privateTag]!,
      'id': instance.id,
    };

const _$EnvelopeNotFoundTagEnumMap = {
  EnvelopeNotFoundTag.envelopeNotFound: 'EnvelopeNotFound',
  EnvelopeNotFoundTag.$unknown: r'$unknown',
};
