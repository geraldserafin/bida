// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invitation_not_found.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InvitationNotFound _$InvitationNotFoundFromJson(Map<String, dynamic> json) =>
    InvitationNotFound(
      privateTag: InvitationNotFoundTag.fromJson(json['_tag'] as String),
      id: json['id'] as String,
    );

Map<String, dynamic> _$InvitationNotFoundToJson(InvitationNotFound instance) =>
    <String, dynamic>{
      '_tag': _$InvitationNotFoundTagEnumMap[instance.privateTag]!,
      'id': instance.id,
    };

const _$InvitationNotFoundTagEnumMap = {
  InvitationNotFoundTag.invitationNotFound: 'InvitationNotFound',
  InvitationNotFoundTag.$unknown: r'$unknown',
};
