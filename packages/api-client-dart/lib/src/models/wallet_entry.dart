// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'wallet_entry_kind.dart';

part 'wallet_entry.g.dart';

@JsonSerializable()
class WalletEntry {
  const WalletEntry({
    required this.id,
    required this.kind,
    required this.amountMinor,
    required this.onDate,
    required this.note,
    required this.estimated,
    required this.householdId,
    required this.householdName,
    required this.ruleId,
    required this.createdAt,
  });

  factory WalletEntry.fromJson(Map<String, Object?> json) =>
      _$WalletEntryFromJson(json);

  final String id;
  final WalletEntryKind kind;
  final int amountMinor;
  final String onDate;
  @JsonKey(includeIfNull: true)
  final String? note;
  final bool estimated;
  @JsonKey(includeIfNull: true)
  final String? householdId;
  @JsonKey(includeIfNull: true)
  final String? householdName;
  @JsonKey(includeIfNull: true)
  final String? ruleId;
  final String createdAt;

  Map<String, Object?> toJson() => _$WalletEntryToJson(this);
}
