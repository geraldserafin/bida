// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'legacy_backup.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LegacyBackup _$LegacyBackupFromJson(Map<String, dynamic> json) => LegacyBackup(
  version: (json['version'] as num).toInt(),
  data: Data.fromJson(json['data'] as Map<String, dynamic>),
  exportedAt: json['exportedAt'] as String?,
);

Map<String, dynamic> _$LegacyBackupToJson(LegacyBackup instance) =>
    <String, dynamic>{
      'version': instance.version,
      'exportedAt': instance.exportedAt,
      'data': instance.data,
    };
