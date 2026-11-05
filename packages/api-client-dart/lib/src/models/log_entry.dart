// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'log_entry.g.dart';

@JsonSerializable()
class LogEntry {
  const LogEntry({
    required this.id,
    required this.householdId,
    required this.periodId,
    required this.userId,
    required this.userName,
    required this.action,
    required this.summary,
    required this.createdAt,
    required this.undone,
    required this.canUndo,
  });

  factory LogEntry.fromJson(Map<String, Object?> json) =>
      _$LogEntryFromJson(json);

  final String id;
  final String householdId;
  final String periodId;
  @JsonKey(includeIfNull: true)
  final String? userId;
  final String userName;
  final String action;
  final String summary;
  final String createdAt;
  final bool undone;
  final bool canUndo;

  Map<String, Object?> toJson() => _$LogEntryToJson(this);
}
