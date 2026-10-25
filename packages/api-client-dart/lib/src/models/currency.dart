// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum Currency {
  @JsonValue('PLN')
  pln('PLN'),
  @JsonValue('EUR')
  eur('EUR'),
  @JsonValue('USD')
  usd('USD'),
  @JsonValue('GBP')
  gbp('GBP'),
  @JsonValue('CHF')
  chf('CHF'),
  @JsonValue('CZK')
  czk('CZK'),
  @JsonValue('SEK')
  sek('SEK'),
  @JsonValue('NOK')
  nok('NOK'),
  @JsonValue('DKK')
  dkk('DKK'),
  @JsonValue('HUF')
  huf('HUF'),
  @JsonValue('JPY')
  jpy('JPY'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const Currency(this.json);

  factory Currency.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<Currency> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
