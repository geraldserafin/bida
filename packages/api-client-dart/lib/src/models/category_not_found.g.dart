// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_not_found.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryNotFound _$CategoryNotFoundFromJson(Map<String, dynamic> json) =>
    CategoryNotFound(
      privateTag: CategoryNotFoundTag.fromJson(json['_tag'] as String),
      id: json['id'] as String,
    );

Map<String, dynamic> _$CategoryNotFoundToJson(CategoryNotFound instance) =>
    <String, dynamic>{
      '_tag': _$CategoryNotFoundTagEnumMap[instance.privateTag]!,
      'id': instance.id,
    };

const _$CategoryNotFoundTagEnumMap = {
  CategoryNotFoundTag.categoryNotFound: 'CategoryNotFound',
  CategoryNotFoundTag.$unknown: r'$unknown',
};
