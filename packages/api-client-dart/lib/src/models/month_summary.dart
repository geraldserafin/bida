// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'month_summary.g.dart';

@JsonSerializable()
class MonthSummary {
  const MonthSummary({
    required this.from,
    required this.to,
    required this.incomeMinor,
    required this.allocatedMinor,
    required this.spentMinor,
  });

  factory MonthSummary.fromJson(Map<String, Object?> json) =>
      _$MonthSummaryFromJson(json);

  final String from;
  final String to;
  final int incomeMinor;
  final int allocatedMinor;
  final int spentMinor;

  Map<String, Object?> toJson() => _$MonthSummaryToJson(this);
}
