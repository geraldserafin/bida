// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_period.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreatePeriod _$CreatePeriodFromJson(Map<String, dynamic> json) => CreatePeriod(
  name: json['name'] as String,
  startDate: json['startDate'] as String,
  endDate: json['endDate'] as String,
  incomeMinor: (json['incomeMinor'] as num).toInt(),
  envelopes: (json['envelopes'] as List<dynamic>)
      .map((e) => EnvelopePlan.fromJson(e as Map<String, dynamic>))
      .toList(),
  currency: json['currency'] == null
      ? null
      : Currency.fromJson(json['currency'] as String),
);

Map<String, dynamic> _$CreatePeriodToJson(CreatePeriod instance) =>
    <String, dynamic>{
      'name': instance.name,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
      'incomeMinor': instance.incomeMinor,
      'currency': ?_$CurrencyEnumMap[instance.currency],
      'envelopes': instance.envelopes,
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
