// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'period_not_current.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PeriodNotCurrent _$PeriodNotCurrentFromJson(Map<String, dynamic> json) =>
    PeriodNotCurrent(
      privateTag: PeriodNotCurrentTag.fromJson(json['_tag'] as String),
      periodId: json['periodId'] as String,
    );

Map<String, dynamic> _$PeriodNotCurrentToJson(PeriodNotCurrent instance) =>
    <String, dynamic>{
      '_tag': _$PeriodNotCurrentTagEnumMap[instance.privateTag]!,
      'periodId': instance.periodId,
    };

const _$PeriodNotCurrentTagEnumMap = {
  PeriodNotCurrentTag.periodNotCurrent: 'PeriodNotCurrent',
  PeriodNotCurrentTag.$unknown: r'$unknown',
};
