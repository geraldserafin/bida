// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'period.dart';

part 'period_summary.g.dart';

@JsonSerializable()
class PeriodSummary {
  const PeriodSummary({
    required this.period,
    required this.plannedMinor,
    required this.spentMinor,
    required this.contributedMinor,
  });

  factory PeriodSummary.fromJson(Map<String, Object?> json) =>
      _$PeriodSummaryFromJson(json);

  final Period period;
  final int plannedMinor;
  final int spentMinor;
  final int contributedMinor;

  Map<String, Object?> toJson() => _$PeriodSummaryToJson(this);
}
