// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'parent_must_be_top_level_tag.dart';

part 'parent_must_be_top_level.g.dart';

@JsonSerializable()
class ParentMustBeTopLevel {
  const ParentMustBeTopLevel({
    required this.privateTag,
    required this.parentId,
  });

  factory ParentMustBeTopLevel.fromJson(Map<String, Object?> json) =>
      _$ParentMustBeTopLevelFromJson(json);

  @JsonKey(name: '_tag')
  final ParentMustBeTopLevelTag privateTag;
  final String parentId;

  Map<String, Object?> toJson() => _$ParentMustBeTopLevelToJson(this);
}
