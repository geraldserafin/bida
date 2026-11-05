// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'cycle_kind.dart';

part 'cycle.g.dart';

@JsonSerializable()
class Cycle {
  const Cycle({
    required this.kind,
    required this.day,
    required this.weeks,
    required this.anchorOn,
  });

  factory Cycle.fromJson(Map<String, Object?> json) => _$CycleFromJson(json);

  final CycleKind kind;
  @JsonKey(includeIfNull: true)
  final int? day;
  @JsonKey(includeIfNull: true)
  final int? weeks;
  @JsonKey(includeIfNull: true)
  final String? anchorOn;

  Map<String, Object?> toJson() => _$CycleToJson(this);
}
