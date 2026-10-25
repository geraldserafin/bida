// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'envelope_progress.dart';

part 'period_progress.g.dart';

@JsonSerializable()
class PeriodProgress {
  const PeriodProgress({
    required this.periodId,
    required this.incomeMinor,
    required this.plannedMinor,
    required this.spentMinor,
    required this.remainingMinor,
    required this.unallocatedMinor,
    required this.envelopes,
  });

  factory PeriodProgress.fromJson(Map<String, Object?> json) =>
      _$PeriodProgressFromJson(json);

  final String periodId;
  final int incomeMinor;
  final int plannedMinor;
  final int spentMinor;
  final int remainingMinor;
  final int unallocatedMinor;
  final List<EnvelopeProgress> envelopes;

  Map<String, Object?> toJson() => _$PeriodProgressToJson(this);
}
