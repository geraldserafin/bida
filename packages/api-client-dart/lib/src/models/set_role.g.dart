// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_role.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetRole _$SetRoleFromJson(Map<String, dynamic> json) =>
    SetRole(role: Role.fromJson(json['role'] as String));

Map<String, dynamic> _$SetRoleToJson(SetRole instance) => <String, dynamic>{
  'role': _$RoleEnumMap[instance.role]!,
};

const _$RoleEnumMap = {
  Role.owner: 'owner',
  Role.member: 'member',
  Role.$unknown: r'$unknown',
};
