// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'forbidden_tag.dart';

part 'forbidden.g.dart';

@JsonSerializable()
class Forbidden {
  const Forbidden({required this.privateTag});

  factory Forbidden.fromJson(Map<String, Object?> json) =>
      _$ForbiddenFromJson(json);

  @JsonKey(name: '_tag')
  final ForbiddenTag privateTag;

  Map<String, Object?> toJson() => _$ForbiddenToJson(this);
}
