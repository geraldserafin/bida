// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'allocation_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AllocationRule _$AllocationRuleFromJson(Map<String, dynamic> json) =>
    AllocationRule(
      id: json['id'] as String,
      userId: json['userId'] as String,
      envelopeId: json['envelopeId'] as String,
      amountMinor: (json['amountMinor'] as num).toInt(),
      dayOfMonth: (json['dayOfMonth'] as num).toInt(),
      note: json['note'] as String?,
      active: json['active'] as bool,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );

Map<String, dynamic> _$AllocationRuleToJson(AllocationRule instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'envelopeId': instance.envelopeId,
      'amountMinor': instance.amountMinor,
      'dayOfMonth': instance.dayOfMonth,
      'note': instance.note,
      'active': instance.active,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
