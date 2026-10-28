// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'limit_reached.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LimitReached _$LimitReachedFromJson(Map<String, dynamic> json) => LimitReached(
  privateTag: LimitReachedTag.fromJson(json['_tag'] as String),
  limit: (json['limit'] as num).toInt(),
);

Map<String, dynamic> _$LimitReachedToJson(LimitReached instance) =>
    <String, dynamic>{
      '_tag': _$LimitReachedTagEnumMap[instance.privateTag]!,
      'limit': instance.limit,
    };

const _$LimitReachedTagEnumMap = {
  LimitReachedTag.limitReached: 'LimitReached',
  LimitReachedTag.$unknown: r'$unknown',
};
