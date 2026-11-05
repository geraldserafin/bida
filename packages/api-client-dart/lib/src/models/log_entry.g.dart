// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LogEntry _$LogEntryFromJson(Map<String, dynamic> json) => LogEntry(
  id: json['id'] as String,
  householdId: json['householdId'] as String,
  periodId: json['periodId'] as String,
  userId: json['userId'] as String?,
  userName: json['userName'] as String,
  action: json['action'] as String,
  summary: json['summary'] as String,
  createdAt: json['createdAt'] as String,
  undone: json['undone'] as bool,
  canUndo: json['canUndo'] as bool,
);

Map<String, dynamic> _$LogEntryToJson(LogEntry instance) => <String, dynamic>{
  'id': instance.id,
  'householdId': instance.householdId,
  'periodId': instance.periodId,
  'userId': instance.userId,
  'userName': instance.userName,
  'action': instance.action,
  'summary': instance.summary,
  'createdAt': instance.createdAt,
  'undone': instance.undone,
  'canUndo': instance.canUndo,
};
