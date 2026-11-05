// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'period_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PeriodSummary _$PeriodSummaryFromJson(Map<String, dynamic> json) =>
    PeriodSummary(
      period: Period.fromJson(json['period'] as Map<String, dynamic>),
      transfersMinor: (json['transfersMinor'] as num).toInt(),
      withdrawalsMinor: (json['withdrawalsMinor'] as num).toInt(),
      carryInMinor: (json['carryInMinor'] as num).toInt(),
      spentMinor: (json['spentMinor'] as num).toInt(),
      estimatedSpentMinor: (json['estimatedSpentMinor'] as num).toInt(),
      balanceMinor: (json['balanceMinor'] as num).toInt(),
      plansTotalMinor: (json['plansTotalMinor'] as num).toInt(),
      remainingPlansMinor: (json['remainingPlansMinor'] as num).toInt(),
      freeMinor: (json['freeMinor'] as num).toInt(),
      plansExceedBalance: json['plansExceedBalance'] as bool,
      carryOutMinor: (json['carryOutMinor'] as num?)?.toInt(),
      nobodyMinor: (json['nobodyMinor'] as num).toInt(),
      nobodyLeftMinor: (json['nobodyLeftMinor'] as num).toInt(),
      envelopes: (json['envelopes'] as List<dynamic>)
          .map((e) => EnvelopeFigures.fromJson(e as Map<String, dynamic>))
          .toList(),
      shares: (json['shares'] as List<dynamic>)
          .map((e) => ShareFigures.fromJson(e as Map<String, dynamic>))
          .toList(),
      forecast: json['forecast'] == null
          ? null
          : Forecast.fromJson(json['forecast'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PeriodSummaryToJson(PeriodSummary instance) =>
    <String, dynamic>{
      'period': instance.period,
      'transfersMinor': instance.transfersMinor,
      'withdrawalsMinor': instance.withdrawalsMinor,
      'carryInMinor': instance.carryInMinor,
      'spentMinor': instance.spentMinor,
      'estimatedSpentMinor': instance.estimatedSpentMinor,
      'balanceMinor': instance.balanceMinor,
      'plansTotalMinor': instance.plansTotalMinor,
      'remainingPlansMinor': instance.remainingPlansMinor,
      'freeMinor': instance.freeMinor,
      'plansExceedBalance': instance.plansExceedBalance,
      'carryOutMinor': instance.carryOutMinor,
      'nobodyMinor': instance.nobodyMinor,
      'nobodyLeftMinor': instance.nobodyLeftMinor,
      'envelopes': instance.envelopes,
      'shares': instance.shares,
      'forecast': instance.forecast,
    };
