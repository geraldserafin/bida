// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'space.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Space _$SpaceFromJson(Map<String, dynamic> json) => Space(
  id: json['id'] as String,
  name: json['name'] as String,
  defaultCurrency: Currency.fromJson(json['defaultCurrency'] as String),
  kind: SpaceKind.fromJson(json['kind'] as String),
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
);

Map<String, dynamic> _$SpaceToJson(Space instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'defaultCurrency': _$CurrencyEnumMap[instance.defaultCurrency]!,
  'kind': _$SpaceKindEnumMap[instance.kind]!,
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

const _$SpaceKindEnumMap = {
  SpaceKind.personal: 'personal',
  SpaceKind.shared: 'shared',
  SpaceKind.$unknown: r'$unknown',
};
