// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_expense.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateExpense _$UpdateExpenseFromJson(Map<String, dynamic> json) =>
    UpdateExpense(
      envelopeId: json['envelopeId'] as String,
      amountMinor: (json['amountMinor'] as num).toInt(),
      spentAt: json['spentAt'] as String,
      note: json['note'] as String?,
      original: json['original'] == null
          ? null
          : OriginalAmount.fromJson(json['original'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$UpdateExpenseToJson(UpdateExpense instance) =>
    <String, dynamic>{
      'envelopeId': instance.envelopeId,
      'amountMinor': instance.amountMinor,
      'spentAt': instance.spentAt,
      'note': instance.note,
      'original': ?instance.original,
    };
