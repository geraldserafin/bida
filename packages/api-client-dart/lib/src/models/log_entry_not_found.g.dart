// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_entry_not_found.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LogEntryNotFound _$LogEntryNotFoundFromJson(Map<String, dynamic> json) =>
    LogEntryNotFound(
      privateTag: LogEntryNotFoundTag.fromJson(json['_tag'] as String),
      id: json['id'] as String,
    );

Map<String, dynamic> _$LogEntryNotFoundToJson(LogEntryNotFound instance) =>
    <String, dynamic>{
      '_tag': _$LogEntryNotFoundTagEnumMap[instance.privateTag]!,
      'id': instance.id,
    };

const _$LogEntryNotFoundTagEnumMap = {
  LogEntryNotFoundTag.logEntryNotFound: 'LogEntryNotFound',
  LogEntryNotFoundTag.$unknown: r'$unknown',
};
