// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'invitation_not_found_tag.dart';

part 'invitation_not_found.g.dart';

@JsonSerializable()
class InvitationNotFound {
  const InvitationNotFound({required this.privateTag, required this.id});

  factory InvitationNotFound.fromJson(Map<String, Object?> json) =>
      _$InvitationNotFoundFromJson(json);

  @JsonKey(name: '_tag')
  final InvitationNotFoundTag privateTag;
  final String id;

  Map<String, Object?> toJson() => _$InvitationNotFoundToJson(this);
}
