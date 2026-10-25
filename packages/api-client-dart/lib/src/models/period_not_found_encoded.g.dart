// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'period_not_found_encoded.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PeriodNotFoundEncoded _$PeriodNotFoundEncodedFromJson(
  Map<String, dynamic> json,
) => PeriodNotFoundEncoded(
  privateTag: PeriodNotFoundEncodedTag.fromJson(json['_tag'] as String),
  id: json['id'] as String,
);

Map<String, dynamic> _$PeriodNotFoundEncodedToJson(
  PeriodNotFoundEncoded instance,
) => <String, dynamic>{
  '_tag': _$PeriodNotFoundEncodedTagEnumMap[instance.privateTag]!,
  'id': instance.id,
};

const _$PeriodNotFoundEncodedTagEnumMap = {
  PeriodNotFoundEncodedTag.periodNotFound: 'PeriodNotFound',
  PeriodNotFoundEncodedTag.$unknown: r'$unknown',
};
