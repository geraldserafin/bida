// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'period.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Period _$PeriodFromJson(Map<String, dynamic> json) => Period(
  id: json['id'] as String,
  householdId: json['householdId'] as String,
  startsOn: json['startsOn'] as String,
  endsOn: json['endsOn'] as String,
  status: PeriodStatus.fromJson(json['status'] as String),
);

Map<String, dynamic> _$PeriodToJson(Period instance) => <String, dynamic>{
  'id': instance.id,
  'householdId': instance.householdId,
  'startsOn': instance.startsOn,
  'endsOn': instance.endsOn,
  'status': _$PeriodStatusEnumMap[instance.status]!,
};

const _$PeriodStatusEnumMap = {
  PeriodStatus.current: 'current',
  PeriodStatus.next: 'next',
  PeriodStatus.closed: 'closed',
  PeriodStatus.$unknown: r'$unknown',
};
