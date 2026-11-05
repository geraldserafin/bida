// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'closed_summary.g.dart';

@JsonSerializable()
class ClosedSummary {
  const ClosedSummary({
    required this.periodId,
    required this.householdId,
    required this.householdName,
    required this.startsOn,
    required this.endsOn,
    required this.transfersMinor,
    required this.withdrawalsMinor,
    required this.carryInMinor,
    required this.spentMinor,
    required this.carryOutMinor,
  });

  factory ClosedSummary.fromJson(Map<String, Object?> json) =>
      _$ClosedSummaryFromJson(json);

  final String periodId;
  final String householdId;
  final String householdName;
  final String startsOn;
  final String endsOn;
  final int transfersMinor;
  final int withdrawalsMinor;
  final int carryInMinor;
  final int spentMinor;
  final int carryOutMinor;

  Map<String, Object?> toJson() => _$ClosedSummaryToJson(this);
}
