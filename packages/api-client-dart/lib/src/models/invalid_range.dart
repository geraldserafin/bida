// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'invalid_range_tag.dart';

part 'invalid_range.g.dart';

@JsonSerializable()
class InvalidRange {
  const InvalidRange({
    required this.privateTag,
    required this.from,
    required this.to,
  });

  factory InvalidRange.fromJson(Map<String, Object?> json) =>
      _$InvalidRangeFromJson(json);

  @JsonKey(name: '_tag')
  final InvalidRangeTag privateTag;
  final String from;
  final String to;

  Map<String, Object?> toJson() => _$InvalidRangeToJson(this);
}
