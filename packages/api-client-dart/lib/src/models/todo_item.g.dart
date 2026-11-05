// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TodoItem _$TodoItemFromJson(Map<String, dynamic> json) => TodoItem(
  id: json['id'] as String,
  kind: TodoKind.fromJson(json['kind'] as String),
  householdId: json['householdId'] as String?,
  householdName: json['householdName'] as String?,
  periodId: json['periodId'] as String?,
  ruleId: json['ruleId'] as String?,
  refId: json['refId'] as String?,
  envelopeId: json['envelopeId'] as String?,
  occurrenceOn: json['occurrenceOn'] as String?,
  amountMinor: (json['amountMinor'] as num).toInt(),
  title: json['title'] as String?,
  createdAt: json['createdAt'] as String,
);

Map<String, dynamic> _$TodoItemToJson(TodoItem instance) => <String, dynamic>{
  'id': instance.id,
  'kind': _$TodoKindEnumMap[instance.kind]!,
  'householdId': instance.householdId,
  'householdName': instance.householdName,
  'periodId': instance.periodId,
  'ruleId': instance.ruleId,
  'refId': instance.refId,
  'envelopeId': instance.envelopeId,
  'occurrenceOn': instance.occurrenceOn,
  'amountMinor': instance.amountMinor,
  'title': instance.title,
  'createdAt': instance.createdAt,
};

const _$TodoKindEnumMap = {
  TodoKind.incomeEstimate: 'income_estimate',
  TodoKind.transferNoMoney: 'transfer_no_money',
  TodoKind.expenseNotFit: 'expense_not_fit',
  TodoKind.expenseEstimate: 'expense_estimate',
  TodoKind.expenseMissed: 'expense_missed',
  TodoKind.$unknown: r'$unknown',
};
