// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'allocation_not_found.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AllocationNotFound _$AllocationNotFoundFromJson(Map<String, dynamic> json) =>
    AllocationNotFound(
      privateTag: AllocationNotFoundTag.fromJson(json['_tag'] as String),
      id: json['id'] as String,
    );

Map<String, dynamic> _$AllocationNotFoundToJson(AllocationNotFound instance) =>
    <String, dynamic>{
      '_tag': _$AllocationNotFoundTagEnumMap[instance.privateTag]!,
      'id': instance.id,
    };

const _$AllocationNotFoundTagEnumMap = {
  AllocationNotFoundTag.allocationNotFound: 'AllocationNotFound',
  AllocationNotFoundTag.$unknown: r'$unknown',
};
