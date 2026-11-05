// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'member_frozen_tag.dart';

part 'member_frozen.g.dart';

@JsonSerializable()
class MemberFrozen {
  const MemberFrozen({required this.privateTag});

  factory MemberFrozen.fromJson(Map<String, Object?> json) =>
      _$MemberFrozenFromJson(json);

  @JsonKey(name: '_tag')
  final MemberFrozenTag privateTag;

  Map<String, Object?> toJson() => _$MemberFrozenToJson(this);
}
