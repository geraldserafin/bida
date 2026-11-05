// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'cycle.dart';

part 'create_household.g.dart';

@JsonSerializable()
class CreateHousehold {
  const CreateHousehold({
    required this.name,
    this.cycle,
    this.firstEndsOn,
    this.timeZone,
    this.envelopes,
  });

  factory CreateHousehold.fromJson(Map<String, Object?> json) =>
      _$CreateHouseholdFromJson(json);

  final String name;
  @JsonKey(includeIfNull: false)
  final Cycle? cycle;
  @JsonKey(includeIfNull: false)
  final String? firstEndsOn;
  @JsonKey(includeIfNull: false)
  final String? timeZone;
  @JsonKey(includeIfNull: false)
  final List<String>? envelopes;

  Map<String, Object?> toJson() => _$CreateHouseholdToJson(this);
}
