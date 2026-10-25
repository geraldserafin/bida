// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'legacy_split.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LegacySplit _$LegacySplitFromJson(Map<String, dynamic> json) => LegacySplit(
  id: (json['id'] as num).toInt(),
  periodId: (json['period_id'] as num).toInt(),
  categoryId: (json['category_id'] as num).toInt(),
  plannedAmount: json['planned_amount'] as num,
);

Map<String, dynamic> _$LegacySplitToJson(LegacySplit instance) =>
    <String, dynamic>{
      'id': instance.id,
      'period_id': instance.periodId,
      'category_id': instance.categoryId,
      'planned_amount': instance.plannedAmount,
    };
