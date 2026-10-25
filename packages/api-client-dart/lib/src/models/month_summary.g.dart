// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'month_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MonthSummary _$MonthSummaryFromJson(Map<String, dynamic> json) => MonthSummary(
  from: json['from'] as String,
  to: json['to'] as String,
  incomeMinor: (json['incomeMinor'] as num).toInt(),
  allocatedMinor: (json['allocatedMinor'] as num).toInt(),
  spentMinor: (json['spentMinor'] as num).toInt(),
);

Map<String, dynamic> _$MonthSummaryToJson(MonthSummary instance) =>
    <String, dynamic>{
      'from': instance.from,
      'to': instance.to,
      'incomeMinor': instance.incomeMinor,
      'allocatedMinor': instance.allocatedMinor,
      'spentMinor': instance.spentMinor,
    };
