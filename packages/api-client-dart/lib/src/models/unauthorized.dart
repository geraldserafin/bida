// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'unauthorized_tag.dart';

part 'unauthorized.g.dart';

@JsonSerializable()
class Unauthorized {
  const Unauthorized({required this.privateTag});

  factory Unauthorized.fromJson(Map<String, Object?> json) =>
      _$UnauthorizedFromJson(json);

  @JsonKey(name: '_tag')
  final UnauthorizedTag privateTag;

  Map<String, Object?> toJson() => _$UnauthorizedToJson(this);
}
