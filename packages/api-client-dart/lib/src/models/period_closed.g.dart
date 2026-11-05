// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'period_closed.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PeriodClosed _$PeriodClosedFromJson(Map<String, dynamic> json) => PeriodClosed(
  privateTag: PeriodClosedTag.fromJson(json['_tag'] as String),
  periodId: json['periodId'] as String,
);

Map<String, dynamic> _$PeriodClosedToJson(PeriodClosed instance) =>
    <String, dynamic>{
      '_tag': _$PeriodClosedTagEnumMap[instance.privateTag]!,
      'periodId': instance.periodId,
    };

const _$PeriodClosedTagEnumMap = {
  PeriodClosedTag.periodClosed: 'PeriodClosed',
  PeriodClosedTag.$unknown: r'$unknown',
};
