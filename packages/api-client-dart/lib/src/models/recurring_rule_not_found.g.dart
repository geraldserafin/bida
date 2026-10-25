// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_rule_not_found.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecurringRuleNotFound _$RecurringRuleNotFoundFromJson(
  Map<String, dynamic> json,
) => RecurringRuleNotFound(
  privateTag: RecurringRuleNotFoundTag.fromJson(json['_tag'] as String),
  id: json['id'] as String,
);

Map<String, dynamic> _$RecurringRuleNotFoundToJson(
  RecurringRuleNotFound instance,
) => <String, dynamic>{
  '_tag': _$RecurringRuleNotFoundTagEnumMap[instance.privateTag]!,
  'id': instance.id,
};

const _$RecurringRuleNotFoundTagEnumMap = {
  RecurringRuleNotFoundTag.recurringRuleNotFound: 'RecurringRuleNotFound',
  RecurringRuleNotFoundTag.$unknown: r'$unknown',
};
