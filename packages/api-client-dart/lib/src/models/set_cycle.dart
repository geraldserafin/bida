// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'cycle.dart';

part 'set_cycle.g.dart';

@JsonSerializable()
class SetCycle {
  const SetCycle({required this.cycle});

  factory SetCycle.fromJson(Map<String, Object?> json) =>
      _$SetCycleFromJson(json);

  final Cycle cycle;

  Map<String, Object?> toJson() => _$SetCycleToJson(this);
}
