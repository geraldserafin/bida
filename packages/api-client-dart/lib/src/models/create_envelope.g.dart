// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateEnvelope _$CreateEnvelopeFromJson(Map<String, dynamic> json) =>
    CreateEnvelope(
      parentId: json['parentId'] as String?,
      name: json['name'] as String,
      color: json['color'] as String,
      icon: json['icon'] as String?,
    );

Map<String, dynamic> _$CreateEnvelopeToJson(CreateEnvelope instance) =>
    <String, dynamic>{
      'parentId': instance.parentId,
      'name': instance.name,
      'color': instance.color,
      'icon': instance.icon,
    };
