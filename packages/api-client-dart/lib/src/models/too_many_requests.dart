// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'too_many_requests_tag.dart';

part 'too_many_requests.g.dart';

@JsonSerializable()
class TooManyRequests {
  const TooManyRequests({required this.privateTag});

  factory TooManyRequests.fromJson(Map<String, Object?> json) =>
      _$TooManyRequestsFromJson(json);

  @JsonKey(name: '_tag')
  final TooManyRequestsTag privateTag;

  Map<String, Object?> toJson() => _$TooManyRequestsToJson(this);
}
