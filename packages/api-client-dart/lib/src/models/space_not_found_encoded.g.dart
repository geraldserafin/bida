// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'space_not_found_encoded.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpaceNotFoundEncoded _$SpaceNotFoundEncodedFromJson(
  Map<String, dynamic> json,
) => SpaceNotFoundEncoded(
  privateTag: SpaceNotFoundEncodedTag.fromJson(json['_tag'] as String),
  id: json['id'] as String,
);

Map<String, dynamic> _$SpaceNotFoundEncodedToJson(
  SpaceNotFoundEncoded instance,
) => <String, dynamic>{
  '_tag': _$SpaceNotFoundEncodedTagEnumMap[instance.privateTag]!,
  'id': instance.id,
};

const _$SpaceNotFoundEncodedTagEnumMap = {
  SpaceNotFoundEncodedTag.spaceNotFound: 'SpaceNotFound',
  SpaceNotFoundEncodedTag.$unknown: r'$unknown',
};
