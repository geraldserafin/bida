// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecurringRule _$RecurringRuleFromJson(Map<String, dynamic> json) =>
    RecurringRule(
      id: json['id'] as String,
      categoryId: json['categoryId'] as String,
      amountMinor: (json['amountMinor'] as num).toInt(),
      frequency: RecurringRuleFrequency.fromJson(json['frequency'] as String),
      note: json['note'] as String?,
      active: json['active'] as bool,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );

Map<String, dynamic> _$RecurringRuleToJson(RecurringRule instance) =>
    <String, dynamic>{
      'id': instance.id,
      'categoryId': instance.categoryId,
      'amountMinor': instance.amountMinor,
      'frequency': _$RecurringRuleFrequencyEnumMap[instance.frequency]!,
      'note': instance.note,
      'active': instance.active,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

const _$RecurringRuleFrequencyEnumMap = {
  RecurringRuleFrequency.weekly: 'weekly',
  RecurringRuleFrequency.monthly: 'monthly',
  RecurringRuleFrequency.$unknown: r'$unknown',
};
