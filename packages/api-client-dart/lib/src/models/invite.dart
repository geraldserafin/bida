// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'email.dart';
import 'role.dart';

part 'invite.g.dart';

@JsonSerializable()
class Invite {
  const Invite({required this.email, required this.role});

  factory Invite.fromJson(Map<String, Object?> json) => _$InviteFromJson(json);

  final Email email;
  final Role role;

  Map<String, Object?> toJson() => _$InviteToJson(this);
}
