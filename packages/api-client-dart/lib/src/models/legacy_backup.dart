// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'data.dart';

part 'legacy_backup.g.dart';

@JsonSerializable()
class LegacyBackup {
  const LegacyBackup({
    required this.version,
    required this.data,
    this.exportedAt,
  });

  factory LegacyBackup.fromJson(Map<String, Object?> json) =>
      _$LegacyBackupFromJson(json);

  final int version;
  final String? exportedAt;
  final Data data;

  Map<String, Object?> toJson() => _$LegacyBackupToJson(this);
}
