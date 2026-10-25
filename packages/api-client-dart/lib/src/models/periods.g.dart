// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'periods.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Periods _$PeriodsFromJson(Map<String, dynamic> json) => Periods(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  startDate: json['start_date'] as String,
  endDate: json['end_date'] as String,
  income: json['income'],
);

Map<String, dynamic> _$PeriodsToJson(Periods instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'start_date': instance.startDate,
  'end_date': instance.endDate,
  'income': instance.income,
};
