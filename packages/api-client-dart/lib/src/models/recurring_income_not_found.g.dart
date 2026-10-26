// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_income_not_found.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecurringIncomeNotFound _$RecurringIncomeNotFoundFromJson(
  Map<String, dynamic> json,
) => RecurringIncomeNotFound(
  privateTag: RecurringIncomeNotFoundTag.fromJson(json['_tag'] as String),
  id: json['id'] as String,
);

Map<String, dynamic> _$RecurringIncomeNotFoundToJson(
  RecurringIncomeNotFound instance,
) => <String, dynamic>{
  '_tag': _$RecurringIncomeNotFoundTagEnumMap[instance.privateTag]!,
  'id': instance.id,
};

const _$RecurringIncomeNotFoundTagEnumMap = {
  RecurringIncomeNotFoundTag.recurringIncomeNotFound: 'RecurringIncomeNotFound',
  RecurringIncomeNotFoundTag.$unknown: r'$unknown',
};
