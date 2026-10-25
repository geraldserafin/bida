// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'legacy_recurring_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LegacyRecurringRule _$LegacyRecurringRuleFromJson(Map<String, dynamic> json) =>
    LegacyRecurringRule(
      id: (json['id'] as num).toInt(),
      categoryId: (json['category_id'] as num).toInt(),
      amount: json['amount'] as num,
      frequency: json['frequency'] as String,
      note: json['note'] as String?,
      active: (json['active'] as num).toInt(),
    );

Map<String, dynamic> _$LegacyRecurringRuleToJson(
  LegacyRecurringRule instance,
) => <String, dynamic>{
  'id': instance.id,
  'category_id': instance.categoryId,
  'amount': instance.amount,
  'frequency': instance.frequency,
  'note': instance.note,
  'active': instance.active,
};
