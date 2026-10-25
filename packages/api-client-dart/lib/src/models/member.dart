// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'email.dart';
import 'role.dart';

part 'member.g.dart';

@JsonSerializable()
class Member {
  const Member({
    required this.userId,
    required this.email,
    required this.name,
    required this.role,
    required this.joinedAt,
  });

  factory Member.fromJson(Map<String, Object?> json) => _$MemberFromJson(json);

  final String userId;
  final Email email;
  @JsonKey(includeIfNull: true)
  final String? name;
  final Role role;
  final String joinedAt;

  Map<String, Object?> toJson() => _$MemberToJson(this);
}
