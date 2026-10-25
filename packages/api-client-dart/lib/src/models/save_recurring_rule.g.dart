// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_recurring_rule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaveRecurringRule _$SaveRecurringRuleFromJson(Map<String, dynamic> json) =>
    SaveRecurringRule(
      categoryId: json['categoryId'] as String,
      amountMinor: (json['amountMinor'] as num).toInt(),
      frequency: SaveRecurringRuleFrequency.fromJson(
        json['frequency'] as String,
      ),
      note: json['note'] as String?,
      active: json['active'] as bool,
      currency: json['currency'] == null
          ? null
          : Currency.fromJson(json['currency'] as String),
    );

Map<String, dynamic> _$SaveRecurringRuleToJson(SaveRecurringRule instance) =>
    <String, dynamic>{
      'categoryId': instance.categoryId,
      'amountMinor': instance.amountMinor,
      'currency': ?_$CurrencyEnumMap[instance.currency],
      'frequency': _$SaveRecurringRuleFrequencyEnumMap[instance.frequency]!,
      'note': instance.note,
      'active': instance.active,
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

const _$SaveRecurringRuleFrequencyEnumMap = {
  SaveRecurringRuleFrequency.weekly: 'weekly',
  SaveRecurringRuleFrequency.monthly: 'monthly',
  SaveRecurringRuleFrequency.$unknown: r'$unknown',
};
