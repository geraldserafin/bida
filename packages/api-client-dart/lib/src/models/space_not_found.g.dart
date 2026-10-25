// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'space_not_found.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpaceNotFound _$SpaceNotFoundFromJson(Map<String, dynamic> json) =>
    SpaceNotFound(
      privateTag: SpaceNotFoundTag.fromJson(json['_tag'] as String),
      id: json['id'] as String,
    );

Map<String, dynamic> _$SpaceNotFoundToJson(SpaceNotFound instance) =>
    <String, dynamic>{
      '_tag': _$SpaceNotFoundTagEnumMap[instance.privateTag]!,
      'id': instance.id,
    };

const _$SpaceNotFoundTagEnumMap = {
  SpaceNotFoundTag.spaceNotFound: 'SpaceNotFound',
  SpaceNotFoundTag.$unknown: r'$unknown',
};
