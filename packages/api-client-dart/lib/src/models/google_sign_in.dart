// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'transport.dart';

part 'google_sign_in.g.dart';

@JsonSerializable()
class GoogleSignIn {
  const GoogleSignIn({required this.idToken, required this.transport});

  factory GoogleSignIn.fromJson(Map<String, Object?> json) =>
      _$GoogleSignInFromJson(json);

  final String idToken;
  final Transport transport;

  Map<String, Object?> toJson() => _$GoogleSignInToJson(this);
}
