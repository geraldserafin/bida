// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'envelope_plan.dart';

part 'set_plan.g.dart';

@JsonSerializable()
class SetPlan {
  const SetPlan({required this.incomeMinor, required this.envelopes});

  factory SetPlan.fromJson(Map<String, Object?> json) =>
      _$SetPlanFromJson(json);

  final int incomeMinor;
  final List<EnvelopePlan> envelopes;

  Map<String, Object?> toJson() => _$SetPlanToJson(this);
}
