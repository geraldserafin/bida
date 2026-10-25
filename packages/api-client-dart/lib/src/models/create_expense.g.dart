// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_expense.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateExpense _$CreateExpenseFromJson(Map<String, dynamic> json) =>
    CreateExpense(
      envelopeId: json['envelopeId'] as String,
      amountMinor: (json['amountMinor'] as num).toInt(),
      spentAt: json['spentAt'] as String,
      note: json['note'] as String?,
      original: json['original'] == null
          ? null
          : OriginalAmount.fromJson(json['original'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CreateExpenseToJson(CreateExpense instance) =>
    <String, dynamic>{
      'envelopeId': instance.envelopeId,
      'amountMinor': instance.amountMinor,
      'spentAt': instance.spentAt,
      'note': instance.note,
      'original': ?instance.original,
    };
