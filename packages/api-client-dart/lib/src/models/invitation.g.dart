// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invitation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Invitation _$InvitationFromJson(Map<String, dynamic> json) => Invitation(
  id: json['id'] as String,
  householdId: json['householdId'] as String,
  householdName: json['householdName'] as String,
  email: json['email'] as Email,
  role: Role.fromJson(json['role'] as String),
  invitedBy: json['invitedBy'] == null
      ? null
      : InvitedBy.fromJson(json['invitedBy'] as Map<String, dynamic>),
  expiresAt: json['expiresAt'] as String,
  createdAt: json['createdAt'] as String,
);

Map<String, dynamic> _$InvitationToJson(Invitation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'householdId': instance.householdId,
      'householdName': instance.householdName,
      'email': instance.email,
      'role': _$RoleEnumMap[instance.role]!,
      'invitedBy': instance.invitedBy,
      'expiresAt': instance.expiresAt,
      'createdAt': instance.createdAt,
    };

const _$RoleEnumMap = {
  Role.owner: 'owner',
  Role.member: 'member',
  Role.$unknown: r'$unknown',
};
