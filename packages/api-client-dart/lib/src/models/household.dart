// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'cycle.dart';
import 'period.dart';
import 'role.dart';

part 'household.g.dart';

@JsonSerializable()
class Household {
  const Household({
    required this.id,
    required this.name,
    required this.timeZone,
    required this.cycle,
    required this.role,
    required this.frozen,
    required this.memberCount,
    required this.current,
    required this.next,
    required this.balanceMinor,
    required this.createdAt,
  });

  factory Household.fromJson(Map<String, Object?> json) =>
      _$HouseholdFromJson(json);

  final String id;
  final String name;
  final String timeZone;
  final Cycle cycle;
  final Role role;
  final bool frozen;
  final int memberCount;
  final Period current;
  @JsonKey(includeIfNull: true)
  final Period? next;
  final int balanceMinor;
  final String createdAt;

  Map<String, Object?> toJson() => _$HouseholdToJson(this);
}
