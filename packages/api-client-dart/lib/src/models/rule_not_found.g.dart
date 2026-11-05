// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rule_not_found.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RuleNotFound _$RuleNotFoundFromJson(Map<String, dynamic> json) => RuleNotFound(
  privateTag: RuleNotFoundTag.fromJson(json['_tag'] as String),
  id: json['id'] as String,
);

Map<String, dynamic> _$RuleNotFoundToJson(RuleNotFound instance) =>
    <String, dynamic>{
      '_tag': _$RuleNotFoundTagEnumMap[instance.privateTag]!,
      'id': instance.id,
    };

const _$RuleNotFoundTagEnumMap = {
  RuleNotFoundTag.ruleNotFound: 'RuleNotFound',
  RuleNotFoundTag.$unknown: r'$unknown',
};
