// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'period_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PeriodDetail _$PeriodDetailFromJson(Map<String, dynamic> json) => PeriodDetail(
  period: Period.fromJson(json['period'] as Map<String, dynamic>),
  envelopes: (json['envelopes'] as List<dynamic>)
      .map((e) => Envelope.fromJson(e as Map<String, dynamic>))
      .toList(),
  plannedMinor: (json['plannedMinor'] as num).toInt(),
  unallocatedMinor: (json['unallocatedMinor'] as num).toInt(),
);

Map<String, dynamic> _$PeriodDetailToJson(PeriodDetail instance) =>
    <String, dynamic>{
      'period': instance.period,
      'envelopes': instance.envelopes,
      'plannedMinor': instance.plannedMinor,
      'unallocatedMinor': instance.unallocatedMinor,
    };
