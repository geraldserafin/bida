// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Envelope _$EnvelopeFromJson(Map<String, dynamic> json) => Envelope(
  id: json['id'] as String,
  householdId: json['householdId'] as String,
  name: json['name'] as String,
  color: json['color'] as String,
  icon: json['icon'] as String?,
  position: (json['position'] as num).toInt(),
  archived: json['archived'] as bool,
);

Map<String, dynamic> _$EnvelopeToJson(Envelope instance) => <String, dynamic>{
  'id': instance.id,
  'householdId': instance.householdId,
  'name': instance.name,
  'color': instance.color,
  'icon': instance.icon,
  'position': instance.position,
  'archived': instance.archived,
};
