// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'period_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PeriodProgress _$PeriodProgressFromJson(Map<String, dynamic> json) =>
    PeriodProgress(
      periodId: json['periodId'] as String,
      incomeMinor: (json['incomeMinor'] as num).toInt(),
      plannedMinor: (json['plannedMinor'] as num).toInt(),
      spentMinor: (json['spentMinor'] as num).toInt(),
      remainingMinor: (json['remainingMinor'] as num).toInt(),
      unallocatedMinor: (json['unallocatedMinor'] as num).toInt(),
      envelopes: (json['envelopes'] as List<dynamic>)
          .map((e) => EnvelopeProgress.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PeriodProgressToJson(PeriodProgress instance) =>
    <String, dynamic>{
      'periodId': instance.periodId,
      'incomeMinor': instance.incomeMinor,
      'plannedMinor': instance.plannedMinor,
      'spentMinor': instance.spentMinor,
      'remainingMinor': instance.remainingMinor,
      'unallocatedMinor': instance.unallocatedMinor,
      'envelopes': instance.envelopes,
    };
