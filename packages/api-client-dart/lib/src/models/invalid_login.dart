// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'invalid_login_tag.dart';

part 'invalid_login.g.dart';

@JsonSerializable()
class InvalidLogin {
  const InvalidLogin({required this.privateTag});

  factory InvalidLogin.fromJson(Map<String, Object?> json) =>
      _$InvalidLoginFromJson(json);

  @JsonKey(name: '_tag')
  final InvalidLoginTag privateTag;

  Map<String, Object?> toJson() => _$InvalidLoginToJson(this);
}
