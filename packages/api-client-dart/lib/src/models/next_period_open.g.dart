// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'next_period_open.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NextPeriodOpen _$NextPeriodOpenFromJson(Map<String, dynamic> json) =>
    NextPeriodOpen(
      privateTag: NextPeriodOpenTag.fromJson(json['_tag'] as String),
      periodId: json['periodId'] as String,
    );

Map<String, dynamic> _$NextPeriodOpenToJson(NextPeriodOpen instance) =>
    <String, dynamic>{
      '_tag': _$NextPeriodOpenTagEnumMap[instance.privateTag]!,
      'periodId': instance.periodId,
    };

const _$NextPeriodOpenTagEnumMap = {
  NextPeriodOpenTag.nextPeriodOpen: 'NextPeriodOpen',
  NextPeriodOpenTag.$unknown: r'$unknown',
};
