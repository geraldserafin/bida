// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'envelope.g.dart';

@JsonSerializable()
class Envelope {
  const Envelope({
    required this.id,
    required this.ownerId,
    required this.parentId,
    required this.name,
    required this.color,
    required this.icon,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Envelope.fromJson(Map<String, Object?> json) =>
      _$EnvelopeFromJson(json);

  final String id;
  final String ownerId;
  @JsonKey(includeIfNull: true)
  final String? parentId;
  final String name;
  final String color;
  @JsonKey(includeIfNull: true)
  final String? icon;
  final String createdAt;
  final String updatedAt;

  Map<String, Object?> toJson() => _$EnvelopeToJson(this);
}
