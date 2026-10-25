// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateCategory _$UpdateCategoryFromJson(Map<String, dynamic> json) =>
    UpdateCategory(
      name: json['name'] as String,
      color: json['color'] as String,
      icon: json['icon'] as String?,
    );

Map<String, dynamic> _$UpdateCategoryToJson(UpdateCategory instance) =>
    <String, dynamic>{
      'name': instance.name,
      'color': instance.color,
      'icon': instance.icon,
    };
