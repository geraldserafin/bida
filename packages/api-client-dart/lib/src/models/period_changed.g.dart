// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'period_changed.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PeriodChanged _$PeriodChangedFromJson(Map<String, dynamic> json) =>
    PeriodChanged(
      privateTag: PeriodChangedTag.fromJson(json['_tag'] as String),
      id: json['id'] as String,
    );

Map<String, dynamic> _$PeriodChangedToJson(PeriodChanged instance) =>
    <String, dynamic>{
      '_tag': _$PeriodChangedTagEnumMap[instance.privateTag]!,
      'id': instance.id,
    };

const _$PeriodChangedTagEnumMap = {
  PeriodChangedTag.periodChanged: 'PeriodChanged',
  PeriodChangedTag.$unknown: r'$unknown',
};
