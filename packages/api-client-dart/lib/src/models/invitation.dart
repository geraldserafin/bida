// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'email.dart';
import 'invited_by.dart';
import 'role.dart';

part 'invitation.g.dart';

@JsonSerializable()
class Invitation {
  const Invitation({
    required this.id,
    required this.householdId,
    required this.householdName,
    required this.email,
    required this.role,
    required this.invitedBy,
    required this.expiresAt,
    required this.createdAt,
  });

  factory Invitation.fromJson(Map<String, Object?> json) =>
      _$InvitationFromJson(json);

  final String id;
  final String householdId;
  final String householdName;
  final Email email;
  final Role role;
  @JsonKey(includeIfNull: true)
  final InvitedBy? invitedBy;
  final String expiresAt;
  final String createdAt;

  Map<String, Object?> toJson() => _$InvitationToJson(this);
}
