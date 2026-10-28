// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_recurring_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaveRecurringRule _$SaveRecurringRuleFromJson(Map<String, dynamic> json) =>
    SaveRecurringRule(
      envelopeId: json['envelopeId'] as String,
      amountMinor: (json['amountMinor'] as num).toInt(),
      frequency: SaveRecurringRuleFrequency.fromJson(
        json['frequency'] as String,
      ),
      note: json['note'] as String?,
      active: json['active'] as bool,
    );

Map<String, dynamic> _$SaveRecurringRuleToJson(SaveRecurringRule instance) =>
    <String, dynamic>{
      'envelopeId': instance.envelopeId,
      'amountMinor': instance.amountMinor,
      'frequency': _$SaveRecurringRuleFrequencyEnumMap[instance.frequency]!,
      'note': instance.note,
      'active': instance.active,
    };

const _$SaveRecurringRuleFrequencyEnumMap = {
  SaveRecurringRuleFrequency.monthly: 'monthly',
  SaveRecurringRuleFrequency.$unknown: r'$unknown',
};
