// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Household _$HouseholdFromJson(Map<String, dynamic> json) => Household(
  id: json['id'] as String,
  name: json['name'] as String,
  timeZone: json['timeZone'] as String,
  cycle: Cycle.fromJson(json['cycle'] as Map<String, dynamic>),
  role: Role.fromJson(json['role'] as String),
  frozen: json['frozen'] as bool,
  memberCount: (json['memberCount'] as num).toInt(),
  current: Period.fromJson(json['current'] as Map<String, dynamic>),
  next: json['next'] == null
      ? null
      : Period.fromJson(json['next'] as Map<String, dynamic>),
  balanceMinor: (json['balanceMinor'] as num).toInt(),
  createdAt: json['createdAt'] as String,
);

Map<String, dynamic> _$HouseholdToJson(Household instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'timeZone': instance.timeZone,
  'cycle': instance.cycle,
  'role': _$RoleEnumMap[instance.role]!,
  'frozen': instance.frozen,
  'memberCount': instance.memberCount,
  'current': instance.current,
  'next': instance.next,
  'balanceMinor': instance.balanceMinor,
  'createdAt': instance.createdAt,
};

const _$RoleEnumMap = {
  Role.owner: 'owner',
  Role.member: 'member',
  Role.$unknown: r'$unknown',
};
