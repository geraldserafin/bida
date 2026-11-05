// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'envelope_figures.dart';
import 'forecast.dart';
import 'period.dart';
import 'share_figures.dart';

part 'period_summary.g.dart';

@JsonSerializable()
class PeriodSummary {
  const PeriodSummary({
    required this.period,
    required this.transfersMinor,
    required this.withdrawalsMinor,
    required this.carryInMinor,
    required this.spentMinor,
    required this.estimatedSpentMinor,
    required this.balanceMinor,
    required this.plansTotalMinor,
    required this.remainingPlansMinor,
    required this.freeMinor,
    required this.plansExceedBalance,
    required this.carryOutMinor,
    required this.nobodyMinor,
    required this.nobodyLeftMinor,
    required this.envelopes,
    required this.shares,
    required this.forecast,
  });

  factory PeriodSummary.fromJson(Map<String, Object?> json) =>
      _$PeriodSummaryFromJson(json);

  final Period period;
  final int transfersMinor;
  final int withdrawalsMinor;
  final int carryInMinor;
  final int spentMinor;
  final int estimatedSpentMinor;
  final int balanceMinor;
  final int plansTotalMinor;
  final int remainingPlansMinor;
  final int freeMinor;
  final bool plansExceedBalance;
  @JsonKey(includeIfNull: true)
  final int? carryOutMinor;
  final int nobodyMinor;
  final int nobodyLeftMinor;
  final List<EnvelopeFigures> envelopes;
  final List<ShareFigures> shares;
  @JsonKey(includeIfNull: true)
  final Forecast? forecast;

  Map<String, Object?> toJson() => _$PeriodSummaryToJson(this);
}
