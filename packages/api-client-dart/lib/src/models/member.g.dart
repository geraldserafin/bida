// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Member _$MemberFromJson(Map<String, dynamic> json) => Member(
  userId: json['userId'] as String,
  email: json['email'] as Email,
  name: json['name'] as String?,
  role: Role.fromJson(json['role'] as String),
  joinedAt: json['joinedAt'] as String,
);

Map<String, dynamic> _$MemberToJson(Member instance) => <String, dynamic>{
  'userId': instance.userId,
  'email': instance.email,
  'name': instance.name,
  'role': _$RoleEnumMap[instance.role]!,
  'joinedAt': instance.joinedAt,
};

const _$RoleEnumMap = {
  Role.owner: 'owner',
  Role.member: 'member',
  Role.$unknown: r'$unknown',
};
