// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_income.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecurringIncome _$RecurringIncomeFromJson(Map<String, dynamic> json) =>
    RecurringIncome(
      id: json['id'] as String,
      userId: json['userId'] as String,
      amountMinor: (json['amountMinor'] as num).toInt(),
      dayOfMonth: (json['dayOfMonth'] as num).toInt(),
      note: json['note'] as String?,
      active: json['active'] as bool,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
    );

Map<String, dynamic> _$RecurringIncomeToJson(RecurringIncome instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'amountMinor': instance.amountMinor,
      'dayOfMonth': instance.dayOfMonth,
      'note': instance.note,
      'active': instance.active,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };
