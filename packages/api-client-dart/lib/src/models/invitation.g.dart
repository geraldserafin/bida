// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invitation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Invitation _$InvitationFromJson(Map<String, dynamic> json) => Invitation(
  id: json['id'] as String,
  spaceId: json['spaceId'] as String,
  spaceName: json['spaceName'] as String,
  email: json['email'] as Email,
  role: Role.fromJson(json['role'] as String),
  status: InvitationStatus.fromJson(json['status'] as String),
  invitedBy: json['invitedBy'] == null
      ? null
      : InvitedBy.fromJson(json['invitedBy'] as Map<String, dynamic>),
  acceptedBy: json['acceptedBy'] as String?,
  expiresAt: json['expiresAt'] as String,
  createdAt: json['createdAt'] as String,
);

Map<String, dynamic> _$InvitationToJson(Invitation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'spaceId': instance.spaceId,
      'spaceName': instance.spaceName,
      'email': instance.email,
      'role': _$RoleEnumMap[instance.role]!,
      'status': _$InvitationStatusEnumMap[instance.status]!,
      'invitedBy': instance.invitedBy,
      'acceptedBy': instance.acceptedBy,
      'expiresAt': instance.expiresAt,
      'createdAt': instance.createdAt,
    };

const _$RoleEnumMap = {
  Role.owner: 'owner',
  Role.member: 'member',
  Role.$unknown: r'$unknown',
};

const _$InvitationStatusEnumMap = {
  InvitationStatus.invited: 'invited',
  InvitationStatus.accepted: 'accepted',
  InvitationStatus.$unknown: r'$unknown',
};
