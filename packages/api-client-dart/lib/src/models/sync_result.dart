// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'closed_summary.dart';

part 'sync_result.g.dart';

@JsonSerializable()
class SyncResult {
  const SyncResult({
    required this.closedPeriods,
    required this.openedPeriods,
    required this.incomes,
    required this.transfers,
    required this.expenses,
    required this.todo,
    required this.summaries,
  });

  factory SyncResult.fromJson(Map<String, Object?> json) =>
      _$SyncResultFromJson(json);

  final int closedPeriods;
  final int openedPeriods;
  final int incomes;
  final int transfers;
  final int expenses;
  final int todo;
  final List<ClosedSummary> summaries;

  Map<String, Object?> toJson() => _$SyncResultToJson(this);
}
