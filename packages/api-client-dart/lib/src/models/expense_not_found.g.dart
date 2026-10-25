// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_not_found.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExpenseNotFound _$ExpenseNotFoundFromJson(Map<String, dynamic> json) =>
    ExpenseNotFound(
      privateTag: ExpenseNotFoundTag.fromJson(json['_tag'] as String),
      id: json['id'] as String,
    );

Map<String, dynamic> _$ExpenseNotFoundToJson(ExpenseNotFound instance) =>
    <String, dynamic>{
      '_tag': _$ExpenseNotFoundTagEnumMap[instance.privateTag]!,
      'id': instance.id,
    };

const _$ExpenseNotFoundTagEnumMap = {
  ExpenseNotFoundTag.expenseNotFound: 'ExpenseNotFound',
  ExpenseNotFoundTag.$unknown: r'$unknown',
};
