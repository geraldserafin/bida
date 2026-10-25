// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'envelope.dart';
import 'period.dart';

part 'period_detail.g.dart';

@JsonSerializable()
class PeriodDetail {
  const PeriodDetail({
    required this.period,
    required this.envelopes,
    required this.plannedMinor,
    required this.unallocatedMinor,
  });

  factory PeriodDetail.fromJson(Map<String, Object?> json) =>
      _$PeriodDetailFromJson(json);

  final Period period;
  final List<Envelope> envelopes;
  final int plannedMinor;
  final int unallocatedMinor;

  Map<String, Object?> toJson() => _$PeriodDetailToJson(this);
}
