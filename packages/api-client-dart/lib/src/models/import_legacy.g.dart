// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_legacy.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImportLegacy _$ImportLegacyFromJson(Map<String, dynamic> json) => ImportLegacy(
  backup: LegacyBackup.fromJson(json['backup'] as Map<String, dynamic>),
  timeZone: json['timeZone'] as String?,
);

Map<String, dynamic> _$ImportLegacyToJson(ImportLegacy instance) =>
    <String, dynamic>{
      'backup': instance.backup,
      'timeZone': ?instance.timeZone,
    };
