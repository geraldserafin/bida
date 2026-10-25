// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'legacy_split.g.dart';

@JsonSerializable()
class LegacySplit {
  const LegacySplit({
    required this.id,
    required this.periodId,
    required this.categoryId,
    required this.plannedAmount,
  });

  factory LegacySplit.fromJson(Map<String, Object?> json) =>
      _$LegacySplitFromJson(json);

  final int id;
  @JsonKey(name: 'period_id')
  final int periodId;
  @JsonKey(name: 'category_id')
  final int categoryId;
  @JsonKey(name: 'planned_amount')
  final num plannedAmount;

  Map<String, Object?> toJson() => _$LegacySplitToJson(this);
}
