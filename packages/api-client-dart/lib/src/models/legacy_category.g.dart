// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'legacy_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LegacyCategory _$LegacyCategoryFromJson(Map<String, dynamic> json) =>
    LegacyCategory(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      color: json['color'] as String,
      icon: json['icon'] as String?,
    );

Map<String, dynamic> _$LegacyCategoryToJson(LegacyCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'color': instance.color,
      'icon': instance.icon,
    };
