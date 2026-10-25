// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'legacy_backup.dart';

part 'import_legacy.g.dart';

@JsonSerializable()
class ImportLegacy {
  const ImportLegacy({required this.backup, this.timeZone});

  factory ImportLegacy.fromJson(Map<String, Object?> json) =>
      _$ImportLegacyFromJson(json);

  final LegacyBackup backup;
  @JsonKey(includeIfNull: false)
  final String? timeZone;

  Map<String, Object?> toJson() => _$ImportLegacyToJson(this);
}
