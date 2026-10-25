// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_not_found_encoded.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExpenseNotFoundEncoded _$ExpenseNotFoundEncodedFromJson(
  Map<String, dynamic> json,
) => ExpenseNotFoundEncoded(
  privateTag: ExpenseNotFoundEncodedTag.fromJson(json['_tag'] as String),
  id: json['id'] as String,
);

Map<String, dynamic> _$ExpenseNotFoundEncodedToJson(
  ExpenseNotFoundEncoded instance,
) => <String, dynamic>{
  '_tag': _$ExpenseNotFoundEncodedTagEnumMap[instance.privateTag]!,
  'id': instance.id,
};

const _$ExpenseNotFoundEncodedTagEnumMap = {
  ExpenseNotFoundEncodedTag.expenseNotFound: 'ExpenseNotFound',
  ExpenseNotFoundEncodedTag.$unknown: r'$unknown',
};
