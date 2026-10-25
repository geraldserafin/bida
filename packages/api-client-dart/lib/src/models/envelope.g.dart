// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Envelope _$EnvelopeFromJson(Map<String, dynamic> json) => Envelope(
  id: json['id'] as String,
  periodId: json['periodId'] as String,
  categoryId: json['categoryId'] as String,
  plannedMinor: (json['plannedMinor'] as num).toInt(),
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
);

Map<String, dynamic> _$EnvelopeToJson(Envelope instance) => <String, dynamic>{
  'id': instance.id,
  'periodId': instance.periodId,
  'categoryId': instance.categoryId,
  'plannedMinor': instance.plannedMinor,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};
