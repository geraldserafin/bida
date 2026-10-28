// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'income_not_found.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IncomeNotFound _$IncomeNotFoundFromJson(Map<String, dynamic> json) =>
    IncomeNotFound(
      privateTag: IncomeNotFoundTag.fromJson(json['_tag'] as String),
      id: json['id'] as String,
    );

Map<String, dynamic> _$IncomeNotFoundToJson(IncomeNotFound instance) =>
    <String, dynamic>{
      '_tag': _$IncomeNotFoundTagEnumMap[instance.privateTag]!,
      'id': instance.id,
    };

const _$IncomeNotFoundTagEnumMap = {
  IncomeNotFoundTag.incomeNotFound: 'IncomeNotFound',
  IncomeNotFoundTag.$unknown: r'$unknown',
};
