// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateCategory _$CreateCategoryFromJson(Map<String, dynamic> json) =>
    CreateCategory(
      name: json['name'] as String,
      color: json['color'] as String,
      icon: json['icon'] as String?,
    );

Map<String, dynamic> _$CreateCategoryToJson(CreateCategory instance) =>
    <String, dynamic>{
      'name': instance.name,
      'color': instance.color,
      'icon': instance.icon,
    };
