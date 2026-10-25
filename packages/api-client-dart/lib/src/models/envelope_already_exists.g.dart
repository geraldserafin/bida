// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'envelope_already_exists.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnvelopeAlreadyExists _$EnvelopeAlreadyExistsFromJson(
  Map<String, dynamic> json,
) => EnvelopeAlreadyExists(
  privateTag: EnvelopeAlreadyExistsTag.fromJson(json['_tag'] as String),
  periodId: json['periodId'] as String,
  categoryId: json['categoryId'] as String,
);

Map<String, dynamic> _$EnvelopeAlreadyExistsToJson(
  EnvelopeAlreadyExists instance,
) => <String, dynamic>{
  '_tag': _$EnvelopeAlreadyExistsTagEnumMap[instance.privateTag]!,
  'periodId': instance.periodId,
  'categoryId': instance.categoryId,
};

const _$EnvelopeAlreadyExistsTagEnumMap = {
  EnvelopeAlreadyExistsTag.envelopeAlreadyExists: 'EnvelopeAlreadyExists',
  EnvelopeAlreadyExistsTag.$unknown: r'$unknown',
};
