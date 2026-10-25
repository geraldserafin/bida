// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'transport.dart';

part 'google_access_token.g.dart';

@JsonSerializable()
class GoogleAccessToken {
  const GoogleAccessToken({required this.accessToken, required this.transport});

  factory GoogleAccessToken.fromJson(Map<String, Object?> json) =>
      _$GoogleAccessTokenFromJson(json);

  final String accessToken;
  final Transport transport;

  Map<String, Object?> toJson() => _$GoogleAccessTokenToJson(this);
}
