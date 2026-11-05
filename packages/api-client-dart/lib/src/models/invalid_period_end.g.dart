// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invalid_period_end.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvalidPeriodEnd _$InvalidPeriodEndFromJson(Map<String, dynamic> json) =>
    InvalidPeriodEnd(
      privateTag: InvalidPeriodEndTag.fromJson(json['_tag'] as String),
      reason: InvalidPeriodEndReason.fromJson(json['reason'] as String),
    );

Map<String, dynamic> _$InvalidPeriodEndToJson(InvalidPeriodEnd instance) =>
    <String, dynamic>{
      '_tag': _$InvalidPeriodEndTagEnumMap[instance.privateTag]!,
      'reason': _$InvalidPeriodEndReasonEnumMap[instance.reason]!,
    };

const _$InvalidPeriodEndTagEnumMap = {
  InvalidPeriodEndTag.invalidPeriodEnd: 'InvalidPeriodEnd',
  InvalidPeriodEndTag.$unknown: r'$unknown',
};

const _$InvalidPeriodEndReasonEnumMap = {
  InvalidPeriodEndReason.beforeToday: 'beforeToday',
  InvalidPeriodEndReason.overlapsNext: 'overlapsNext',
  InvalidPeriodEndReason.$unknown: r'$unknown',
};
