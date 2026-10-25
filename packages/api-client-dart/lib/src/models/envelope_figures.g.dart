// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'envelope_figures.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnvelopeFigures _$EnvelopeFiguresFromJson(Map<String, dynamic> json) =>
    EnvelopeFigures(
      envelopeId: json['envelopeId'] as String,
      parentId: json['parentId'] as String?,
      openingMinor: (json['openingMinor'] as num).toInt(),
      allocatedMinor: (json['allocatedMinor'] as num).toInt(),
      spentMinor: (json['spentMinor'] as num).toInt(),
      balanceMinor: (json['balanceMinor'] as num).toInt(),
      freeMinor: (json['freeMinor'] as num).toInt(),
    );

Map<String, dynamic> _$EnvelopeFiguresToJson(EnvelopeFigures instance) =>
    <String, dynamic>{
      'envelopeId': instance.envelopeId,
      'parentId': instance.parentId,
      'openingMinor': instance.openingMinor,
      'allocatedMinor': instance.allocatedMinor,
      'spentMinor': instance.spentMinor,
      'balanceMinor': instance.balanceMinor,
      'freeMinor': instance.freeMinor,
    };
