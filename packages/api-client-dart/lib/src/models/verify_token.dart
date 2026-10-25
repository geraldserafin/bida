// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'transport.dart';

part 'verify_token.g.dart';

@JsonSerializable()
class VerifyToken {
  const VerifyToken({required this.token, required this.transport});

  factory VerifyToken.fromJson(Map<String, Object?> json) =>
      _$VerifyTokenFromJson(json);

  final String token;
  final Transport transport;

  Map<String, Object?> toJson() => _$VerifyTokenToJson(this);
}
