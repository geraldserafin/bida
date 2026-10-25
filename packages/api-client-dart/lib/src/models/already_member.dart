// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'already_member_tag.dart';

part 'already_member.g.dart';

@JsonSerializable()
class AlreadyMember {
  const AlreadyMember({required this.privateTag});

  factory AlreadyMember.fromJson(Map<String, Object?> json) =>
      _$AlreadyMemberFromJson(json);

  @JsonKey(name: '_tag')
  final AlreadyMemberTag privateTag;

  Map<String, Object?> toJson() => _$AlreadyMemberToJson(this);
}
