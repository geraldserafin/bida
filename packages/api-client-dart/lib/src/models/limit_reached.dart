// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'limit_reached_tag.dart';

part 'limit_reached.g.dart';

@JsonSerializable()
class LimitReached {
  const LimitReached({required this.privateTag, required this.limit});

  factory LimitReached.fromJson(Map<String, Object?> json) =>
      _$LimitReachedFromJson(json);

  @JsonKey(name: '_tag')
  final LimitReachedTag privateTag;
  final int limit;

  Map<String, Object?> toJson() => _$LimitReachedToJson(this);
}
