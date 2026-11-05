// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_too_small.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanTooSmall _$PlanTooSmallFromJson(Map<String, dynamic> json) => PlanTooSmall(
  privateTag: PlanTooSmallTag.fromJson(json['_tag'] as String),
  envelopeId: json['envelopeId'] as String,
  planShortMinor: (json['planShortMinor'] as num).toInt(),
  freeMinor: (json['freeMinor'] as num).toInt(),
  balanceMinor: (json['balanceMinor'] as num).toInt(),
  transferMinor: (json['transferMinor'] as num).toInt(),
);

Map<String, dynamic> _$PlanTooSmallToJson(PlanTooSmall instance) =>
    <String, dynamic>{
      '_tag': _$PlanTooSmallTagEnumMap[instance.privateTag]!,
      'envelopeId': instance.envelopeId,
      'planShortMinor': instance.planShortMinor,
      'freeMinor': instance.freeMinor,
      'balanceMinor': instance.balanceMinor,
      'transferMinor': instance.transferMinor,
    };

const _$PlanTooSmallTagEnumMap = {
  PlanTooSmallTag.planTooSmall: 'PlanTooSmall',
  PlanTooSmallTag.$unknown: r'$unknown',
};
