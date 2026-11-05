// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'plan_below_spent_tag.dart';

part 'plan_below_spent.g.dart';

@JsonSerializable()
class PlanBelowSpent {
  const PlanBelowSpent({
    required this.privateTag,
    required this.envelopeId,
    required this.spentMinor,
  });

  factory PlanBelowSpent.fromJson(Map<String, Object?> json) =>
      _$PlanBelowSpentFromJson(json);

  @JsonKey(name: '_tag')
  final PlanBelowSpentTag privateTag;
  final String envelopeId;
  final int spentMinor;

  Map<String, Object?> toJson() => _$PlanBelowSpentToJson(this);
}
