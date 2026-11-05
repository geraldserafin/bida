// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Expense _$ExpenseFromJson(Map<String, dynamic> json) => Expense(
  id: json['id'] as String,
  householdId: json['householdId'] as String,
  periodId: json['periodId'] as String,
  envelopeId: json['envelopeId'] as String,
  createdBy: json['createdBy'] as String?,
  authorName: json['authorName'] as String,
  amountMinor: (json['amountMinor'] as num).toInt(),
  spentAt: json['spentAt'] as String,
  title: json['title'] as String?,
  forWhom: json['forWhom'] == null
      ? null
      : ForWhom.fromJson(json['forWhom'] as String),
  forWhomUserId: json['forWhomUserId'] as String?,
  forWhomName: json['forWhomName'] as String?,
  estimated: json['estimated'] as bool,
  ruleId: json['ruleId'] as String?,
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
);

Map<String, dynamic> _$ExpenseToJson(Expense instance) => <String, dynamic>{
  'id': instance.id,
  'householdId': instance.householdId,
  'periodId': instance.periodId,
  'envelopeId': instance.envelopeId,
  'createdBy': instance.createdBy,
  'authorName': instance.authorName,
  'amountMinor': instance.amountMinor,
  'spentAt': instance.spentAt,
  'title': instance.title,
  'forWhom': _$ForWhomEnumMap[instance.forWhom],
  'forWhomUserId': instance.forWhomUserId,
  'forWhomName': instance.forWhomName,
  'estimated': instance.estimated,
  'ruleId': instance.ruleId,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};

const _$ForWhomEnumMap = {
  ForWhom.member: 'member',
  ForWhom.shared: 'shared',
  ForWhom.$unknown: r'$unknown',
};
