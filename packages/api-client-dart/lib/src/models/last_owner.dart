// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'last_owner_tag.dart';

part 'last_owner.g.dart';

@JsonSerializable()
class LastOwner {
  const LastOwner({required this.privateTag});

  factory LastOwner.fromJson(Map<String, Object?> json) =>
      _$LastOwnerFromJson(json);

  @JsonKey(name: '_tag')
  final LastOwnerTag privateTag;

  Map<String, Object?> toJson() => _$LastOwnerToJson(this);
}
