// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_income.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateIncome _$CreateIncomeFromJson(Map<String, dynamic> json) => CreateIncome(
  amountMinor: (json['amountMinor'] as num).toInt(),
  onDate: json['onDate'] as String,
  note: json['note'] as String?,
  estimated: json['estimated'] as bool,
);

Map<String, dynamic> _$CreateIncomeToJson(CreateIncome instance) =>
    <String, dynamic>{
      'amountMinor': instance.amountMinor,
      'onDate': instance.onDate,
      'note': instance.note,
      'estimated': instance.estimated,
    };
