// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_space.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaveSpace _$SaveSpaceFromJson(Map<String, dynamic> json) => SaveSpace(
  name: json['name'] as String,
  defaultCurrency: Currency.fromJson(json['defaultCurrency'] as String),
);

Map<String, dynamic> _$SaveSpaceToJson(SaveSpace instance) => <String, dynamic>{
  'name': instance.name,
  'defaultCurrency': _$CurrencyEnumMap[instance.defaultCurrency]!,
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
