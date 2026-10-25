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
  originalAmountMinor: (json['originalAmountMinor'] as num?)?.toInt(),
  originalCurrency: json['originalCurrency'] == null
      ? null
      : Currency.fromJson(json['originalCurrency'] as String),
  spentAt: json['spentAt'] as String,
  note: json['note'] as String?,
  recurringId: json['recurringId'] as String?,
  createdBy: json['createdBy'] as String?,
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
);

Map<String, dynamic> _$ExpenseToJson(Expense instance) => <String, dynamic>{
  'id': instance.id,
  'envelopeId': instance.envelopeId,
  'periodId': instance.periodId,
  'amountMinor': instance.amountMinor,
  'originalAmountMinor': instance.originalAmountMinor,
  'originalCurrency': _$CurrencyEnumMap[instance.originalCurrency],
  'spentAt': instance.spentAt,
  'note': instance.note,
  'recurringId': instance.recurringId,
  'createdBy': instance.createdBy,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};

const _$CurrencyEnumMap = {
  Currency.pln: 'PLN',
  Currency.eur: 'EUR',
  Currency.usd: 'USD',
  Currency.gbp: 'GBP',
  Currency.chf: 'CHF',
  Currency.czk: 'CZK',
  Currency.sek: 'SEK',
  Currency.nok: 'NOK',
  Currency.dkk: 'DKK',
  Currency.huf: 'HUF',
  Currency.jpy: 'JPY',
  Currency.$unknown: r'$unknown',
};
