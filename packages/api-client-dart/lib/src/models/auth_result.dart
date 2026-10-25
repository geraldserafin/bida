// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'user.dart';

part 'auth_result.g.dart';

@JsonSerializable()
class AuthResult {
  const AuthResult({required this.user, this.token});

  factory AuthResult.fromJson(Map<String, Object?> json) =>
      _$AuthResultFromJson(json);

  final User user;
  @JsonKey(includeIfNull: false)
  final String? token;

  Map<String, Object?> toJson() => _$AuthResultToJson(this);
}
