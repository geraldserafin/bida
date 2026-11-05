// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'invalid_schedule_tag.dart';

part 'invalid_schedule.g.dart';

@JsonSerializable()
class InvalidSchedule {
  const InvalidSchedule({required this.privateTag});

  factory InvalidSchedule.fromJson(Map<String, Object?> json) =>
      _$InvalidScheduleFromJson(json);

  @JsonKey(name: '_tag')
  final InvalidScheduleTag privateTag;

  Map<String, Object?> toJson() => _$InvalidScheduleToJson(this);
}
