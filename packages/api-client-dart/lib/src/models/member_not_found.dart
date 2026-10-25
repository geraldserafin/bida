// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'member_not_found_tag.dart';

part 'member_not_found.g.dart';

@JsonSerializable()
class MemberNotFound {
  const MemberNotFound({required this.privateTag, required this.userId});

  factory MemberNotFound.fromJson(Map<String, Object?> json) =>
      _$MemberNotFoundFromJson(json);

  @JsonKey(name: '_tag')
  final MemberNotFoundTag privateTag;
  final String userId;

  Map<String, Object?> toJson() => _$MemberNotFoundToJson(this);
}
