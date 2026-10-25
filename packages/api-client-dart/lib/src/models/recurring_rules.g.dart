// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_rules.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecurringRules _$RecurringRulesFromJson(Map<String, dynamic> json) =>
    RecurringRules(
      id: (json['id'] as num).toInt(),
      categoryId: (json['category_id'] as num).toInt(),
      amount: json['amount'],
      frequency: json['frequency'] as String,
      note: json['note'] as String?,
      active: (json['active'] as num).toInt(),
    );

Map<String, dynamic> _$RecurringRulesToJson(RecurringRules instance) =>
    <String, dynamic>{
      'id': instance.id,
      'category_id': instance.categoryId,
      'amount': instance.amount,
      'frequency': instance.frequency,
      'note': instance.note,
      'active': instance.active,
    };
