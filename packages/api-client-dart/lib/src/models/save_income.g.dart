// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'save_income.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SaveIncome _$SaveIncomeFromJson(Map<String, dynamic> json) => SaveIncome(
  amountMinor: (json['amountMinor'] as num).toInt(),
  receivedOn: json['receivedOn'] as String,
  note: json['note'] as String?,
);

Map<String, dynamic> _$SaveIncomeToJson(SaveIncome instance) =>
    <String, dynamic>{
      'amountMinor': instance.amountMinor,
      'receivedOn': instance.receivedOn,
      'note': instance.note,
    };
