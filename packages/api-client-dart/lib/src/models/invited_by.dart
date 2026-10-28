// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'email.dart';

part 'invited_by.g.dart';

@JsonSerializable()
class InvitedBy {
  const InvitedBy({required this.email, required this.name});

  factory InvitedBy.fromJson(Map<String, Object?> json) =>
      _$InvitedByFromJson(json);

  final Email email;
  @JsonKey(includeIfNull: true)
  final String? name;

  Map<String, Object?> toJson() => _$InvitedByToJson(this);
}
