// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'create_envelope.g.dart';

@JsonSerializable()
class CreateEnvelope {
  const CreateEnvelope({
    required this.parentId,
    required this.name,
    required this.color,
    required this.icon,
  });

  factory CreateEnvelope.fromJson(Map<String, Object?> json) =>
      _$CreateEnvelopeFromJson(json);

  @JsonKey(includeIfNull: true)
  final String? parentId;
  final String name;
  final String color;
  @JsonKey(includeIfNull: true)
  final String? icon;

  Map<String, Object?> toJson() => _$CreateEnvelopeToJson(this);
}
