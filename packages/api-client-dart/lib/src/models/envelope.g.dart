// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Envelope _$EnvelopeFromJson(Map<String, dynamic> json) => Envelope(
  id: json['id'] as String,
  ownerId: json['ownerId'] as String,
  parentId: json['parentId'] as String?,
  name: json['name'] as String,
  color: json['color'] as String,
  icon: json['icon'] as String?,
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
);

Map<String, dynamic> _$EnvelopeToJson(Envelope instance) => <String, dynamic>{
  'id': instance.id,
  'ownerId': instance.ownerId,
  'parentId': instance.parentId,
  'name': instance.name,
  'color': instance.color,
  'icon': instance.icon,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};
