// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_not_found.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemberNotFound _$MemberNotFoundFromJson(Map<String, dynamic> json) =>
    MemberNotFound(
      privateTag: MemberNotFoundTag.fromJson(json['_tag'] as String),
      userId: json['userId'] as String,
    );

Map<String, dynamic> _$MemberNotFoundToJson(MemberNotFound instance) =>
    <String, dynamic>{
      '_tag': _$MemberNotFoundTagEnumMap[instance.privateTag]!,
      'userId': instance.userId,
    };

const _$MemberNotFoundTagEnumMap = {
  MemberNotFoundTag.memberNotFound: 'MemberNotFound',
  MemberNotFoundTag.$unknown: r'$unknown',
};
