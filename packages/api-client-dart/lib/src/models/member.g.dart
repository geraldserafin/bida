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
  frozen: json['frozen'] as bool,
  joinedAt: json['joinedAt'] as String,
  shareMinor: (json['shareMinor'] as num).toInt(),
);

Map<String, dynamic> _$MemberToJson(Member instance) => <String, dynamic>{
  'userId': instance.userId,
  'email': instance.email,
  'name': instance.name,
  'role': _$RoleEnumMap[instance.role]!,
  'frozen': instance.frozen,
  'joinedAt': instance.joinedAt,
  'shareMinor': instance.shareMinor,
};

const _$RoleEnumMap = {
  Role.owner: 'owner',
  Role.member: 'member',
  Role.$unknown: r'$unknown',
};
