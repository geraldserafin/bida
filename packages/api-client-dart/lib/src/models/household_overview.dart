// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'period.dart';

part 'household_overview.g.dart';

@JsonSerializable()
class HouseholdOverview {
  const HouseholdOverview({
    required this.id,
    required this.name,
    required this.current,
    required this.balanceMinor,
    required this.freeMinor,
    required this.spentMinor,
  });

  factory HouseholdOverview.fromJson(Map<String, Object?> json) =>
      _$HouseholdOverviewFromJson(json);

  final String id;
  final String name;
  final Period current;
  final int balanceMinor;
  final int freeMinor;
  final int spentMinor;

  Map<String, Object?> toJson() => _$HouseholdOverviewToJson(this);
}
