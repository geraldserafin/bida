// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_in_use_encoded.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryInUseEncoded _$CategoryInUseEncodedFromJson(
  Map<String, dynamic> json,
) => CategoryInUseEncoded(
  privateTag: CategoryInUseEncodedTag.fromJson(json['_tag'] as String),
  id: json['id'] as String,
);

Map<String, dynamic> _$CategoryInUseEncodedToJson(
  CategoryInUseEncoded instance,
) => <String, dynamic>{
  '_tag': _$CategoryInUseEncodedTagEnumMap[instance.privateTag]!,
  'id': instance.id,
};

const _$CategoryInUseEncodedTagEnumMap = {
  CategoryInUseEncodedTag.categoryInUse: 'CategoryInUse',
  CategoryInUseEncodedTag.$unknown: r'$unknown',
};
