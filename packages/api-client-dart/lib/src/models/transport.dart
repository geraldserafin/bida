// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

/// `token` returns the session token in the response body (mobile apps); `cookie` sets it as an HTTP-only cookie instead (browser apps).
@JsonEnum()
enum Transport {
  @JsonValue('token')
  token('token'),
  @JsonValue('cookie')
  cookie('cookie'),

  /// Default value for all unparsed values, allows backward compatibility when adding new values on the backend.
  $unknown(null);

  const Transport(this.json);

  factory Transport.fromJson(String json) =>
      values.firstWhere((e) => e.json == json, orElse: () => $unknown);

  final String? json;

  @override
  String toString() => json?.toString() ?? super.toString();

  /// Returns all defined enum values excluding the $unknown value.
  static List<Transport> get $valuesDefined =>
      values.where((value) => value != $unknown).toList();
}
