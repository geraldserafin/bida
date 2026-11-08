// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaveRule _$SaveRuleFromJson(Map<String, dynamic> json) => SaveRule(
  kind: RuleKind.fromJson(json['kind'] as String),
  householdId: json['householdId'] as String?,
  envelopeId: json['envelopeId'] as String?,
  name: json['name'] as String,
  amountMinor: (json['amountMinor'] as num).toInt(),
  estimated: json['estimated'] as bool,
  frequency: SaveRuleFrequency.fromJson(json['frequency'] as String),
  dayOfMonth: (json['dayOfMonth'] as num?)?.toInt(),
  everyWeeks: (json['everyWeeks'] as num?)?.toInt(),
  anchorOn: json['anchorOn'] as String?,
  target: json['target'] == null
      ? null
      : SaveRuleTarget.fromJson(json['target'] as String),
  active: json['active'] as bool,
  startsOn: json['startsOn'] as String?,
  incomeRuleId: json['incomeRuleId'] as String?,
);

Map<String, dynamic> _$SaveRuleToJson(SaveRule instance) => <String, dynamic>{
  'kind': _$RuleKindEnumMap[instance.kind]!,
  'householdId': instance.householdId,
  'envelopeId': instance.envelopeId,
  'name': instance.name,
  'amountMinor': instance.amountMinor,
  'estimated': instance.estimated,
  'frequency': _$SaveRuleFrequencyEnumMap[instance.frequency]!,
  'dayOfMonth': instance.dayOfMonth,
  'everyWeeks': instance.everyWeeks,
  'anchorOn': instance.anchorOn,
  'startsOn': ?instance.startsOn,
  'target': _$SaveRuleTargetEnumMap[instance.target],
  'incomeRuleId': ?instance.incomeRuleId,
  'active': instance.active,
};

const _$RuleKindEnumMap = {
  RuleKind.income: 'income',
  RuleKind.transfer: 'transfer',
  RuleKind.expense: 'expense',
  RuleKind.$unknown: r'$unknown',
};

const _$SaveRuleFrequencyEnumMap = {
  SaveRuleFrequency.monthly: 'monthly',
  SaveRuleFrequency.weeks: 'weeks',
  SaveRuleFrequency.$unknown: r'$unknown',
};

const _$SaveRuleTargetEnumMap = {
  SaveRuleTarget.current: 'current',
  SaveRuleTarget.next: 'next',
  SaveRuleTarget.$unknown: r'$unknown',
};
