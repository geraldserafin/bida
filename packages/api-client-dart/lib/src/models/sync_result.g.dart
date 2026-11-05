// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncResult _$SyncResultFromJson(Map<String, dynamic> json) => SyncResult(
  closedPeriods: (json['closedPeriods'] as num).toInt(),
  openedPeriods: (json['openedPeriods'] as num).toInt(),
  incomes: (json['incomes'] as num).toInt(),
  transfers: (json['transfers'] as num).toInt(),
  expenses: (json['expenses'] as num).toInt(),
  todo: (json['todo'] as num).toInt(),
  summaries: (json['summaries'] as List<dynamic>)
      .map((e) => ClosedSummary.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SyncResultToJson(SyncResult instance) =>
    <String, dynamic>{
      'closedPeriods': instance.closedPeriods,
      'openedPeriods': instance.openedPeriods,
      'incomes': instance.incomes,
      'transfers': instance.transfers,
      'expenses': instance.expenses,
      'todo': instance.todo,
      'summaries': instance.summaries,
    };
