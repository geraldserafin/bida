// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'date_outside_period.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DateOutsidePeriod _$DateOutsidePeriodFromJson(Map<String, dynamic> json) =>
    DateOutsidePeriod(
      privateTag: DateOutsidePeriodTag.fromJson(json['_tag'] as String),
      periodId: json['periodId'] as String,
      startsOn: json['startsOn'] as String,
      endsOn: json['endsOn'] as String,
    );

Map<String, dynamic> _$DateOutsidePeriodToJson(DateOutsidePeriod instance) =>
    <String, dynamic>{
      '_tag': _$DateOutsidePeriodTagEnumMap[instance.privateTag]!,
      'periodId': instance.periodId,
      'startsOn': instance.startsOn,
      'endsOn': instance.endsOn,
    };

const _$DateOutsidePeriodTagEnumMap = {
  DateOutsidePeriodTag.dateOutsidePeriod: 'DateOutsidePeriod',
  DateOutsidePeriodTag.$unknown: r'$unknown',
};
