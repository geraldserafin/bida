// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expenses.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Expenses _$ExpensesFromJson(Map<String, dynamic> json) => Expenses(
  id: (json['id'] as num).toInt(),
  splitId: (json['split_id'] as num).toInt(),
  amount: json['amount'],
  date: json['date'] as String,
  note: json['note'] as String?,
  recurringId: (json['recurring_id'] as num?)?.toInt(),
);

Map<String, dynamic> _$ExpensesToJson(Expenses instance) => <String, dynamic>{
  'id': instance.id,
  'split_id': instance.splitId,
  'amount': instance.amount,
  'date': instance.date,
  'note': instance.note,
  'recurring_id': instance.recurringId,
};
