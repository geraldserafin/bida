// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'envelope_has_expenses.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EnvelopeHasExpenses _$EnvelopeHasExpensesFromJson(Map<String, dynamic> json) =>
    EnvelopeHasExpenses(
      privateTag: EnvelopeHasExpensesTag.fromJson(json['_tag'] as String),
      id: json['id'] as String,
    );

Map<String, dynamic> _$EnvelopeHasExpensesToJson(
  EnvelopeHasExpenses instance,
) => <String, dynamic>{
  '_tag': _$EnvelopeHasExpensesTagEnumMap[instance.privateTag]!,
  'id': instance.id,
};

const _$EnvelopeHasExpensesTagEnumMap = {
  EnvelopeHasExpensesTag.envelopeHasExpenses: 'EnvelopeHasExpenses',
  EnvelopeHasExpensesTag.$unknown: r'$unknown',
};
