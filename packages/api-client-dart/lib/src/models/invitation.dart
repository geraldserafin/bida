// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'email.dart';
import 'invitation_status.dart';
import 'invited_by.dart';
import 'role.dart';

part 'invitation.g.dart';

@JsonSerializable()
class Invitation {
  const Invitation({
    required this.id,
    required this.spaceId,
    required this.spaceName,
    required this.email,
    required this.role,
    required this.status,
    required this.invitedBy,
    required this.acceptedBy,
    required this.expiresAt,
    required this.createdAt,
  });

  factory Invitation.fromJson(Map<String, Object?> json) =>
      _$InvitationFromJson(json);

  final String id;
  final String spaceId;
  final String spaceName;
  final Email email;
  final Role role;
  final InvitationStatus status;
  @JsonKey(includeIfNull: true)
  final InvitedBy? invitedBy;
  @JsonKey(includeIfNull: true)
  final String? acceptedBy;
  final String expiresAt;
  final String createdAt;

  Map<String, Object?> toJson() => _$InvitationToJson(this);
}
