// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'decision.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Decision _$DecisionFromJson(Map<String, dynamic> json) => Decision(
  raisePlan: json['raisePlan'] as bool,
  transferMinor: (json['transferMinor'] as num).toInt(),
  allowNegativeWallet: json['allowNegativeWallet'] as bool,
);

Map<String, dynamic> _$DecisionToJson(Decision instance) => <String, dynamic>{
  'raisePlan': instance.raisePlan,
  'transferMinor': instance.transferMinor,
  'allowNegativeWallet': instance.allowNegativeWallet,
};
