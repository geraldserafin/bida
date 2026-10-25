// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'envelope_already_exists_encoded.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnvelopeAlreadyExistsEncoded _$EnvelopeAlreadyExistsEncodedFromJson(
  Map<String, dynamic> json,
) => EnvelopeAlreadyExistsEncoded(
  privateTag: EnvelopeAlreadyExistsEncodedTag.fromJson(json['_tag'] as String),
  periodId: json['periodId'] as String,
  categoryId: json['categoryId'] as String,
);

Map<String, dynamic> _$EnvelopeAlreadyExistsEncodedToJson(
  EnvelopeAlreadyExistsEncoded instance,
) => <String, dynamic>{
  '_tag': _$EnvelopeAlreadyExistsEncodedTagEnumMap[instance.privateTag]!,
  'periodId': instance.periodId,
  'categoryId': instance.categoryId,
};

const _$EnvelopeAlreadyExistsEncodedTagEnumMap = {
  EnvelopeAlreadyExistsEncodedTag.envelopeAlreadyExists:
      'EnvelopeAlreadyExists',
  EnvelopeAlreadyExistsEncodedTag.$unknown: r'$unknown',
};
