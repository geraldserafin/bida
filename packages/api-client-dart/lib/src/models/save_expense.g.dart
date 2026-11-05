// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_expense.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaveExpense _$SaveExpenseFromJson(Map<String, dynamic> json) => SaveExpense(
  envelopeId: json['envelopeId'] as String,
  amountMinor: (json['amountMinor'] as num).toInt(),
  spentAt: json['spentAt'] as String,
  title: json['title'] as String?,
  forWhom: json['forWhom'] == null
      ? null
      : ForWhom.fromJson(json['forWhom'] as String),
  forWhomUserId: json['forWhomUserId'] as String?,
  decision: json['decision'] == null
      ? null
      : Decision.fromJson(json['decision'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SaveExpenseToJson(SaveExpense instance) =>
    <String, dynamic>{
      'envelopeId': instance.envelopeId,
      'amountMinor': instance.amountMinor,
      'spentAt': instance.spentAt,
      'title': instance.title,
      'forWhom': _$ForWhomEnumMap[instance.forWhom],
      'forWhomUserId': instance.forWhomUserId,
      'decision': ?instance.decision,
    };

const _$ForWhomEnumMap = {
  ForWhom.member: 'member',
  ForWhom.shared: 'shared',
  ForWhom.$unknown: r'$unknown',
};
