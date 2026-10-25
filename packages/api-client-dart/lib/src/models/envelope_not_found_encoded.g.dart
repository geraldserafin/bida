// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'envelope_not_found_encoded.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnvelopeNotFoundEncoded _$EnvelopeNotFoundEncodedFromJson(
  Map<String, dynamic> json,
) => EnvelopeNotFoundEncoded(
  privateTag: EnvelopeNotFoundEncodedTag.fromJson(json['_tag'] as String),
  id: json['id'] as String,
);

Map<String, dynamic> _$EnvelopeNotFoundEncodedToJson(
  EnvelopeNotFoundEncoded instance,
) => <String, dynamic>{
  '_tag': _$EnvelopeNotFoundEncodedTagEnumMap[instance.privateTag]!,
  'id': instance.id,
};

const _$EnvelopeNotFoundEncodedTagEnumMap = {
  EnvelopeNotFoundEncodedTag.envelopeNotFound: 'EnvelopeNotFound',
  EnvelopeNotFoundEncodedTag.$unknown: r'$unknown',
};
