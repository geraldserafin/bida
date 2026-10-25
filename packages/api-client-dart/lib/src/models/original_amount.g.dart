// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'original_amount.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OriginalAmount _$OriginalAmountFromJson(Map<String, dynamic> json) =>
    OriginalAmount(
      amountMinor: (json['amountMinor'] as num).toInt(),
      currency: Currency.fromJson(json['currency'] as String),
    );

Map<String, dynamic> _$OriginalAmountToJson(OriginalAmount instance) =>
    <String, dynamic>{
      'amountMinor': instance.amountMinor,
      'currency': _$CurrencyEnumMap[instance.currency]!,
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
