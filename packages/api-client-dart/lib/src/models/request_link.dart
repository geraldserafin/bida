// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'email.dart';

part 'request_link.g.dart';

@JsonSerializable()
class RequestLink {
  const RequestLink({required this.email});

  factory RequestLink.fromJson(Map<String, Object?> json) =>
      _$RequestLinkFromJson(json);

  final Email email;

  Map<String, Object?> toJson() => _$RequestLinkToJson(this);
}
