// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'envelope_not_found_tag.dart';

part 'envelope_not_found.g.dart';

@JsonSerializable()
class EnvelopeNotFound {
  const EnvelopeNotFound({required this.privateTag, required this.id});

  factory EnvelopeNotFound.fromJson(Map<String, Object?> json) =>
      _$EnvelopeNotFoundFromJson(json);

  @JsonKey(name: '_tag')
  final EnvelopeNotFoundTag privateTag;
  final String id;

  Map<String, Object?> toJson() => _$EnvelopeNotFoundToJson(this);
}
