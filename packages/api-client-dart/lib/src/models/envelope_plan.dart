// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'envelope_plan.g.dart';

@JsonSerializable()
class EnvelopePlan {
  const EnvelopePlan({required this.categoryId, required this.plannedMinor});

  factory EnvelopePlan.fromJson(Map<String, Object?> json) =>
      _$EnvelopePlanFromJson(json);

  final String categoryId;
  final int plannedMinor;

  Map<String, Object?> toJson() => _$EnvelopePlanToJson(this);
}
