// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_rule_not_found_encoded.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecurringRuleNotFoundEncoded _$RecurringRuleNotFoundEncodedFromJson(
  Map<String, dynamic> json,
) => RecurringRuleNotFoundEncoded(
  privateTag: RecurringRuleNotFoundEncodedTag.fromJson(json['_tag'] as String),
  id: json['id'] as String,
);

Map<String, dynamic> _$RecurringRuleNotFoundEncodedToJson(
  RecurringRuleNotFoundEncoded instance,
) => <String, dynamic>{
  '_tag': _$RecurringRuleNotFoundEncodedTagEnumMap[instance.privateTag]!,
  'id': instance.id,
};

const _$RecurringRuleNotFoundEncodedTagEnumMap = {
  RecurringRuleNotFoundEncodedTag.recurringRuleNotFound:
      'RecurringRuleNotFound',
  RecurringRuleNotFoundEncodedTag.$unknown: r'$unknown',
};
