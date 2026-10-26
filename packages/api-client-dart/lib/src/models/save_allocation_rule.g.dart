// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_allocation_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaveAllocationRule _$SaveAllocationRuleFromJson(Map<String, dynamic> json) =>
    SaveAllocationRule(
      envelopeId: json['envelopeId'] as String,
      amountMinor: (json['amountMinor'] as num).toInt(),
      dayOfMonth: (json['dayOfMonth'] as num).toInt(),
      note: json['note'] as String?,
      active: json['active'] as bool,
    );

Map<String, dynamic> _$SaveAllocationRuleToJson(SaveAllocationRule instance) =>
    <String, dynamic>{
      'envelopeId': instance.envelopeId,
      'amountMinor': instance.amountMinor,
      'dayOfMonth': instance.dayOfMonth,
      'note': instance.note,
      'active': instance.active,
    };
