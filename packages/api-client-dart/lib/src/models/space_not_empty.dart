// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'space_not_empty_tag.dart';

part 'space_not_empty.g.dart';

@JsonSerializable()
class SpaceNotEmpty {
  const SpaceNotEmpty({required this.privateTag});

  factory SpaceNotEmpty.fromJson(Map<String, Object?> json) =>
      _$SpaceNotEmptyFromJson(json);

  @JsonKey(name: '_tag')
  final SpaceNotEmptyTag privateTag;

  Map<String, Object?> toJson() => _$SpaceNotEmptyToJson(this);
}
