// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'personal_space.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PersonalSpace _$PersonalSpaceFromJson(Map<String, dynamic> json) =>
    PersonalSpace(
      privateTag: PersonalSpaceTag.fromJson(json['_tag'] as String),
    );

Map<String, dynamic> _$PersonalSpaceToJson(PersonalSpace instance) =>
    <String, dynamic>{'_tag': _$PersonalSpaceTagEnumMap[instance.privateTag]!};

const _$PersonalSpaceTagEnumMap = {
  PersonalSpaceTag.personalSpace: 'PersonalSpace',
  PersonalSpaceTag.$unknown: r'$unknown',
};
