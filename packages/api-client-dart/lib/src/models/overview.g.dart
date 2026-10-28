// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'overview.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Overview _$OverviewFromJson(Map<String, dynamic> json) => Overview(
  from: json['from'] as String,
  to: json['to'] as String,
  incomeMinor: (json['incomeMinor'] as num).toInt(),
  allocatedMinor: (json['allocatedMinor'] as num).toInt(),
  spentMinor: (json['spentMinor'] as num).toInt(),
  poolMinor: (json['poolMinor'] as num).toInt(),
  envelopes: (json['envelopes'] as List<dynamic>)
      .map((e) => EnvelopeFigures.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$OverviewToJson(Overview instance) => <String, dynamic>{
  'from': instance.from,
  'to': instance.to,
  'incomeMinor': instance.incomeMinor,
  'allocatedMinor': instance.allocatedMinor,
  'spentMinor': instance.spentMinor,
  'poolMinor': instance.poolMinor,
  'envelopes': instance.envelopes,
};
