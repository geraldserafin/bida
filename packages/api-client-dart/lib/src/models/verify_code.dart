// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'email.dart';
import 'transport.dart';

part 'verify_code.g.dart';

@JsonSerializable()
class VerifyCode {
  const VerifyCode({
    required this.email,
    required this.code,
    required this.transport,
  });

  factory VerifyCode.fromJson(Map<String, Object?> json) =>
      _$VerifyCodeFromJson(json);

  final Email email;
  final String code;
  final Transport transport;

  Map<String, Object?> toJson() => _$VerifyCodeToJson(this);
}
