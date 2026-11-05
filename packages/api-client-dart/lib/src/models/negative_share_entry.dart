// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'negative_share_entry.g.dart';

@JsonSerializable()
class NegativeShareEntry {
  const NegativeShareEntry({
    required this.householdId,
    required this.householdName,
    required this.periodId,
    required this.userId,
    required this.name,
    required this.shareMinor,
  });

  factory NegativeShareEntry.fromJson(Map<String, Object?> json) =>
      _$NegativeShareEntryFromJson(json);

  final String householdId;
  final String householdName;
  final String periodId;
  final String userId;
  final String name;
  final int shareMinor;

  Map<String, Object?> toJson() => _$NegativeShareEntryToJson(this);
}
