// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'period_not_found.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PeriodNotFound _$PeriodNotFoundFromJson(Map<String, dynamic> json) =>
    PeriodNotFound(
      privateTag: PeriodNotFoundTag.fromJson(json['_tag'] as String),
      id: json['id'] as String,
    );

Map<String, dynamic> _$PeriodNotFoundToJson(PeriodNotFound instance) =>
    <String, dynamic>{
      '_tag': _$PeriodNotFoundTagEnumMap[instance.privateTag]!,
      'id': instance.id,
    };

const _$PeriodNotFoundTagEnumMap = {
  PeriodNotFoundTag.periodNotFound: 'PeriodNotFound',
  PeriodNotFoundTag.$unknown: r'$unknown',
};
