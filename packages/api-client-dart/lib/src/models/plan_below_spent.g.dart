// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_below_spent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlanBelowSpent _$PlanBelowSpentFromJson(Map<String, dynamic> json) =>
    PlanBelowSpent(
      privateTag: PlanBelowSpentTag.fromJson(json['_tag'] as String),
      envelopeId: json['envelopeId'] as String,
      spentMinor: (json['spentMinor'] as num).toInt(),
    );

Map<String, dynamic> _$PlanBelowSpentToJson(PlanBelowSpent instance) =>
    <String, dynamic>{
      '_tag': _$PlanBelowSpentTagEnumMap[instance.privateTag]!,
      'envelopeId': instance.envelopeId,
      'spentMinor': instance.spentMinor,
    };

const _$PlanBelowSpentTagEnumMap = {
  PlanBelowSpentTag.planBelowSpent: 'PlanBelowSpent',
  PlanBelowSpentTag.$unknown: r'$unknown',
};
