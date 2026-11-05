// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remove_income.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RemoveIncome _$RemoveIncomeFromJson(Map<String, dynamic> json) => RemoveIncome(
  correction: json['correction'] == null
      ? null
      : Correction.fromJson(json['correction'] as Map<String, dynamic>),
);

Map<String, dynamic> _$RemoveIncomeToJson(RemoveIncome instance) =>
    <String, dynamic>{'correction': ?instance.correction};
