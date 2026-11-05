// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecurringRule _$RecurringRuleFromJson(Map<String, dynamic> json) =>
    RecurringRule(
      id: json['id'] as String,
      kind: RuleKind.fromJson(json['kind'] as String),
      userId: json['userId'] as String,
      householdId: json['householdId'] as String?,
      envelopeId: json['envelopeId'] as String?,
      name: json['name'] as String,
      amountMinor: (json['amountMinor'] as num).toInt(),
      estimated: json['estimated'] as bool,
      frequency: RecurringRuleFrequency.fromJson(json['frequency'] as String),
      dayOfMonth: (json['dayOfMonth'] as num?)?.toInt(),
      everyWeeks: (json['everyWeeks'] as num?)?.toInt(),
      anchorOn: json['anchorOn'] as String?,
      startsOn: json['startsOn'] as String,
      target: json['target'] == null
          ? null
          : RecurringRuleTarget.fromJson(json['target'] as String),
      active: json['active'] as bool,
    );

Map<String, dynamic> _$RecurringRuleToJson(RecurringRule instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': _$RuleKindEnumMap[instance.kind]!,
      'userId': instance.userId,
      'householdId': instance.householdId,
      'envelopeId': instance.envelopeId,
      'name': instance.name,
      'amountMinor': instance.amountMinor,
      'estimated': instance.estimated,
      'frequency': _$RecurringRuleFrequencyEnumMap[instance.frequency]!,
      'dayOfMonth': instance.dayOfMonth,
      'everyWeeks': instance.everyWeeks,
      'anchorOn': instance.anchorOn,
      'startsOn': instance.startsOn,
      'target': _$RecurringRuleTargetEnumMap[instance.target],
      'active': instance.active,
    };

const _$RuleKindEnumMap = {
  RuleKind.income: 'income',
  RuleKind.transfer: 'transfer',
  RuleKind.expense: 'expense',
  RuleKind.$unknown: r'$unknown',
};

const _$RecurringRuleFrequencyEnumMap = {
  RecurringRuleFrequency.monthly: 'monthly',
  RecurringRuleFrequency.weeks: 'weeks',
  RecurringRuleFrequency.$unknown: r'$unknown',
};

const _$RecurringRuleTargetEnumMap = {
  RecurringRuleTarget.current: 'current',
  RecurringRuleTarget.next: 'next',
  RecurringRuleTarget.$unknown: r'$unknown',
};
