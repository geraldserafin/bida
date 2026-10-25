// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Expense _$ExpenseFromJson(Map<String, dynamic> json) => Expense(
  id: json['id'] as String,
  envelopeId: json['envelopeId'] as String,
  periodId: json['periodId'] as String,
  amountMinor: (json['amountMinor'] as num).toInt(),
  spentAt: json['spentAt'] as String,
  note: json['note'] as String?,
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
);

Map<String, dynamic> _$ExpenseToJson(Expense instance) => <String, dynamic>{
  'id': instance.id,
  'envelopeId': instance.envelopeId,
  'periodId': instance.periodId,
  'amountMinor': instance.amountMinor,
  'spentAt': instance.spentAt,
  'note': instance.note,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};
