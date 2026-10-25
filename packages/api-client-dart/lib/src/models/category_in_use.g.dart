// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_in_use.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CategoryInUse _$CategoryInUseFromJson(Map<String, dynamic> json) =>
    CategoryInUse(
      privateTag: CategoryInUseTag.fromJson(json['_tag'] as String),
      id: json['id'] as String,
    );

Map<String, dynamic> _$CategoryInUseToJson(CategoryInUse instance) =>
    <String, dynamic>{
      '_tag': _$CategoryInUseTagEnumMap[instance.privateTag]!,
      'id': instance.id,
    };

const _$CategoryInUseTagEnumMap = {
  CategoryInUseTag.categoryInUse: 'CategoryInUse',
  CategoryInUseTag.$unknown: r'$unknown',
};
