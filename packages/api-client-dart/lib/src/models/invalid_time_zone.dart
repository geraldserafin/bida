// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'invalid_time_zone_tag.dart';

part 'invalid_time_zone.g.dart';

@JsonSerializable()
class InvalidTimeZone {
  const InvalidTimeZone({required this.privateTag, required this.timeZone});

  factory InvalidTimeZone.fromJson(Map<String, Object?> json) =>
      _$InvalidTimeZoneFromJson(json);

  @JsonKey(name: '_tag')
  final InvalidTimeZoneTag privateTag;
  final String timeZone;

  Map<String, Object?> toJson() => _$InvalidTimeZoneToJson(this);
}
