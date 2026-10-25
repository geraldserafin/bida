// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'space_not_found_tag.dart';

part 'space_not_found.g.dart';

@JsonSerializable()
class SpaceNotFound {
  const SpaceNotFound({required this.privateTag, required this.id});

  factory SpaceNotFound.fromJson(Map<String, Object?> json) =>
      _$SpaceNotFoundFromJson(json);

  @JsonKey(name: '_tag')
  final SpaceNotFoundTag privateTag;
  final String id;

  Map<String, Object?> toJson() => _$SpaceNotFoundToJson(this);
}
