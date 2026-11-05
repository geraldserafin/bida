// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'confirm_income.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConfirmIncome _$ConfirmIncomeFromJson(Map<String, dynamic> json) =>
    ConfirmIncome(
      amountMinor: (json['amountMinor'] as num).toInt(),
      correction: json['correction'] == null
          ? null
          : Correction.fromJson(json['correction'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ConfirmIncomeToJson(ConfirmIncome instance) =>
    <String, dynamic>{
      'amountMinor': instance.amountMinor,
      'correction': ?instance.correction,
    };
