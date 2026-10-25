// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'envelope_not_found_encoded_tag.dart';

part 'envelope_not_found_encoded.g.dart';

@JsonSerializable()
class EnvelopeNotFoundEncoded {
  const EnvelopeNotFoundEncoded({required this.privateTag, required this.id});

  factory EnvelopeNotFoundEncoded.fromJson(Map<String, Object?> json) =>
      _$EnvelopeNotFoundEncodedFromJson(json);

  @JsonKey(name: '_tag')
  final EnvelopeNotFoundEncodedTag privateTag;
  final String id;

  Map<String, Object?> toJson() => _$EnvelopeNotFoundEncodedToJson(this);
}
