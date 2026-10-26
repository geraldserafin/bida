// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_recurring_income.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaveRecurringIncome _$SaveRecurringIncomeFromJson(Map<String, dynamic> json) =>
    SaveRecurringIncome(
      amountMinor: (json['amountMinor'] as num).toInt(),
      dayOfMonth: (json['dayOfMonth'] as num).toInt(),
      note: json['note'] as String?,
      active: json['active'] as bool,
    );

Map<String, dynamic> _$SaveRecurringIncomeToJson(
  SaveRecurringIncome instance,
) => <String, dynamic>{
  'amountMinor': instance.amountMinor,
  'dayOfMonth': instance.dayOfMonth,
  'note': instance.note,
  'active': instance.active,
};
