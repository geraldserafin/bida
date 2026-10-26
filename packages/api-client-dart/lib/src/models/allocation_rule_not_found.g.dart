// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'allocation_rule_not_found.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AllocationRuleNotFound _$AllocationRuleNotFoundFromJson(
  Map<String, dynamic> json,
) => AllocationRuleNotFound(
  privateTag: AllocationRuleNotFoundTag.fromJson(json['_tag'] as String),
  id: json['id'] as String,
);

Map<String, dynamic> _$AllocationRuleNotFoundToJson(
  AllocationRuleNotFound instance,
) => <String, dynamic>{
  '_tag': _$AllocationRuleNotFoundTagEnumMap[instance.privateTag]!,
  'id': instance.id,
};

const _$AllocationRuleNotFoundTagEnumMap = {
  AllocationRuleNotFoundTag.allocationRuleNotFound: 'AllocationRuleNotFound',
  AllocationRuleNotFoundTag.$unknown: r'$unknown',
};
