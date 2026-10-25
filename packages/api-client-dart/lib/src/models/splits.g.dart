// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'splits.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Splits _$SplitsFromJson(Map<String, dynamic> json) => Splits(
  id: (json['id'] as num).toInt(),
  periodId: (json['period_id'] as num).toInt(),
  categoryId: (json['category_id'] as num).toInt(),
  plannedAmount: json['planned_amount'],
);

Map<String, dynamic> _$SplitsToJson(Splits instance) => <String, dynamic>{
  'id': instance.id,
  'period_id': instance.periodId,
  'category_id': instance.categoryId,
  'planned_amount': instance.plannedAmount,
};
