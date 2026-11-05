// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'plan_too_small_tag.dart';

part 'plan_too_small.g.dart';

@JsonSerializable()
class PlanTooSmall {
  const PlanTooSmall({
    required this.privateTag,
    required this.envelopeId,
    required this.planShortMinor,
    required this.freeMinor,
    required this.balanceMinor,
    required this.transferMinor,
  });

  factory PlanTooSmall.fromJson(Map<String, Object?> json) =>
      _$PlanTooSmallFromJson(json);

  @JsonKey(name: '_tag')
  final PlanTooSmallTag privateTag;
  final String envelopeId;
  final int planShortMinor;
  final int freeMinor;
  final int balanceMinor;
  final int transferMinor;

  Map<String, Object?> toJson() => _$PlanTooSmallToJson(this);
}
