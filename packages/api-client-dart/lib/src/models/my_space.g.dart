// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'my_space.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MySpace _$MySpaceFromJson(Map<String, dynamic> json) => MySpace(
  space: Space.fromJson(json['space'] as Map<String, dynamic>),
  role: Role.fromJson(json['role'] as String),
  memberCount: (json['memberCount'] as num).toInt(),
);

Map<String, dynamic> _$MySpaceToJson(MySpace instance) => <String, dynamic>{
  'space': instance.space,
  'role': _$RoleEnumMap[instance.role]!,
  'memberCount': instance.memberCount,
};

const _$RoleEnumMap = {
  Role.owner: 'owner',
  Role.member: 'member',
  Role.$unknown: r'$unknown',
};
