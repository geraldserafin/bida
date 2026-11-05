// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'household_overview.dart';
import 'wallet.dart';

part 'overview.g.dart';

@JsonSerializable()
class Overview {
  const Overview({
    required this.wallet,
    required this.households,
    required this.todo,
  });

  factory Overview.fromJson(Map<String, Object?> json) =>
      _$OverviewFromJson(json);

  final Wallet wallet;
  final List<HouseholdOverview> households;
  final int todo;

  Map<String, Object?> toJson() => _$OverviewToJson(this);
}
