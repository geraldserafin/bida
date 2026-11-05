// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'household_not_found.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HouseholdNotFound _$HouseholdNotFoundFromJson(Map<String, dynamic> json) =>
    HouseholdNotFound(
      privateTag: HouseholdNotFoundTag.fromJson(json['_tag'] as String),
      id: json['id'] as String,
    );

Map<String, dynamic> _$HouseholdNotFoundToJson(HouseholdNotFound instance) =>
    <String, dynamic>{
      '_tag': _$HouseholdNotFoundTagEnumMap[instance.privateTag]!,
      'id': instance.id,
    };

const _$HouseholdNotFoundTagEnumMap = {
  HouseholdNotFoundTag.householdNotFound: 'HouseholdNotFound',
  HouseholdNotFoundTag.$unknown: r'$unknown',
};
