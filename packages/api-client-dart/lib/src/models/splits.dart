// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'splits.g.dart';

@JsonSerializable()
class Splits {
  const Splits({
    required this.id,
    required this.periodId,
    required this.categoryId,
    required this.plannedAmount,
  });

  factory Splits.fromJson(Map<String, Object?> json) => _$SplitsFromJson(json);

  final int id;
  @JsonKey(name: 'period_id')
  final int periodId;
  @JsonKey(name: 'category_id')
  final int categoryId;
  @JsonKey(name: 'planned_amount')
  final dynamic plannedAmount;

  Map<String, Object?> toJson() => _$SplitsToJson(this);
}
