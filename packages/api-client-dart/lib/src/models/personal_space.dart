// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'personal_space_tag.dart';

part 'personal_space.g.dart';

@JsonSerializable()
class PersonalSpace {
  const PersonalSpace({required this.privateTag});

  factory PersonalSpace.fromJson(Map<String, Object?> json) =>
      _$PersonalSpaceFromJson(json);

  @JsonKey(name: '_tag')
  final PersonalSpaceTag privateTag;

  Map<String, Object?> toJson() => _$PersonalSpaceToJson(this);
}
