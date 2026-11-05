// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'not_enough_in_period.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotEnoughInPeriod _$NotEnoughInPeriodFromJson(Map<String, dynamic> json) =>
    NotEnoughInPeriod(
      privateTag: NotEnoughInPeriodTag.fromJson(json['_tag'] as String),
      periodId: json['periodId'] as String,
      balanceMinor: (json['balanceMinor'] as num).toInt(),
      transferMinor: (json['transferMinor'] as num).toInt(),
    );

Map<String, dynamic> _$NotEnoughInPeriodToJson(NotEnoughInPeriod instance) =>
    <String, dynamic>{
      '_tag': _$NotEnoughInPeriodTagEnumMap[instance.privateTag]!,
      'periodId': instance.periodId,
      'balanceMinor': instance.balanceMinor,
      'transferMinor': instance.transferMinor,
    };

const _$NotEnoughInPeriodTagEnumMap = {
  NotEnoughInPeriodTag.notEnoughInPeriod: 'NotEnoughInPeriod',
  NotEnoughInPeriodTag.$unknown: r'$unknown',
};
