// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'set_plan.g.dart';

@JsonSerializable()
class SetPlan {
  const SetPlan({required this.amountMinor});

  factory SetPlan.fromJson(Map<String, Object?> json) =>
      _$SetPlanFromJson(json);

  final int amountMinor;

  Map<String, Object?> toJson() => _$SetPlanToJson(this);
}
