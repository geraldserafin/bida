// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateEnvelope _$UpdateEnvelopeFromJson(Map<String, dynamic> json) =>
    UpdateEnvelope(
      name: json['name'] as String,
      color: json['color'] as String,
      icon: json['icon'] as String?,
    );

Map<String, dynamic> _$UpdateEnvelopeToJson(UpdateEnvelope instance) =>
    <String, dynamic>{
      'name': instance.name,
      'color': instance.color,
      'icon': instance.icon,
    };
