// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_not_found_encoded.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryNotFoundEncoded _$CategoryNotFoundEncodedFromJson(
  Map<String, dynamic> json,
) => CategoryNotFoundEncoded(
  privateTag: CategoryNotFoundEncodedTag.fromJson(json['_tag'] as String),
  id: json['id'] as String,
);

Map<String, dynamic> _$CategoryNotFoundEncodedToJson(
  CategoryNotFoundEncoded instance,
) => <String, dynamic>{
  '_tag': _$CategoryNotFoundEncodedTagEnumMap[instance.privateTag]!,
  'id': instance.id,
};

const _$CategoryNotFoundEncodedTagEnumMap = {
  CategoryNotFoundEncodedTag.categoryNotFound: 'CategoryNotFound',
  CategoryNotFoundEncodedTag.$unknown: r'$unknown',
};
