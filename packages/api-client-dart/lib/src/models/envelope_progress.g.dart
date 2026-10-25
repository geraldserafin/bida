// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'envelope_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnvelopeProgress _$EnvelopeProgressFromJson(Map<String, dynamic> json) =>
    EnvelopeProgress(
      envelopeId: json['envelopeId'] as String,
      categoryId: json['categoryId'] as String,
      plannedMinor: (json['plannedMinor'] as num).toInt(),
      spentMinor: (json['spentMinor'] as num).toInt(),
      remainingMinor: (json['remainingMinor'] as num).toInt(),
    );

Map<String, dynamic> _$EnvelopeProgressToJson(EnvelopeProgress instance) =>
    <String, dynamic>{
      'envelopeId': instance.envelopeId,
      'categoryId': instance.categoryId,
      'plannedMinor': instance.plannedMinor,
      'spentMinor': instance.spentMinor,
      'remainingMinor': instance.remainingMinor,
    };
