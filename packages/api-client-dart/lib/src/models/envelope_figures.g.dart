// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'envelope_figures.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnvelopeFigures _$EnvelopeFiguresFromJson(Map<String, dynamic> json) =>
    EnvelopeFigures(
      envelopeId: json['envelopeId'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      icon: json['icon'] as String?,
      archived: json['archived'] as bool,
      planMinor: (json['planMinor'] as num).toInt(),
      manualMinor: (json['manualMinor'] as num).toInt(),
      recurringMinor: (json['recurringMinor'] as num).toInt(),
      spentMinor: (json['spentMinor'] as num).toInt(),
      leftMinor: (json['leftMinor'] as num).toInt(),
      sharePercent: json['sharePercent'],
      previousSpentMinor: (json['previousSpentMinor'] as num?)?.toInt(),
    );

Map<String, dynamic> _$EnvelopeFiguresToJson(EnvelopeFigures instance) =>
    <String, dynamic>{
      'envelopeId': instance.envelopeId,
      'name': instance.name,
      'color': instance.color,
      'icon': instance.icon,
      'archived': instance.archived,
      'planMinor': instance.planMinor,
      'manualMinor': instance.manualMinor,
      'recurringMinor': instance.recurringMinor,
      'spentMinor': instance.spentMinor,
      'leftMinor': instance.leftMinor,
      'sharePercent': instance.sharePercent,
      'previousSpentMinor': instance.previousSpentMinor,
    };
