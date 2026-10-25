// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'period_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PeriodSummary _$PeriodSummaryFromJson(Map<String, dynamic> json) =>
    PeriodSummary(
      period: Period.fromJson(json['period'] as Map<String, dynamic>),
      plannedMinor: (json['plannedMinor'] as num).toInt(),
      spentMinor: (json['spentMinor'] as num).toInt(),
      contributedMinor: (json['contributedMinor'] as num).toInt(),
    );

Map<String, dynamic> _$PeriodSummaryToJson(PeriodSummary instance) =>
    <String, dynamic>{
      'period': instance.period,
      'plannedMinor': instance.plannedMinor,
      'spentMinor': instance.spentMinor,
      'contributedMinor': instance.contributedMinor,
    };
