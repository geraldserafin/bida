// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'period.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Period _$PeriodFromJson(Map<String, dynamic> json) => Period(
  id: json['id'] as String,
  name: json['name'] as String,
  startDate: json['startDate'] as String,
  endDate: json['endDate'] as String,
  incomeMinor: (json['incomeMinor'] as num).toInt(),
  currency: Currency.fromJson(json['currency'] as String),
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
);

Map<String, dynamic> _$PeriodToJson(Period instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'startDate': instance.startDate,
  'endDate': instance.endDate,
  'incomeMinor': instance.incomeMinor,
  'currency': _$CurrencyEnumMap[instance.currency]!,
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
