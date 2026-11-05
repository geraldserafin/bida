// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_income.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateIncome _$UpdateIncomeFromJson(Map<String, dynamic> json) => UpdateIncome(
  amountMinor: (json['amountMinor'] as num).toInt(),
  onDate: json['onDate'] as String,
  note: json['note'] as String?,
  estimated: json['estimated'] as bool,
  correction: json['correction'] == null
      ? null
      : Correction.fromJson(json['correction'] as Map<String, dynamic>),
);

Map<String, dynamic> _$UpdateIncomeToJson(UpdateIncome instance) =>
    <String, dynamic>{
      'amountMinor': instance.amountMinor,
      'onDate': instance.onDate,
      'note': instance.note,
      'estimated': instance.estimated,
      'correction': ?instance.correction,
    };
