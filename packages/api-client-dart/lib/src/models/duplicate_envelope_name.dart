// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'duplicate_envelope_name_tag.dart';

part 'duplicate_envelope_name.g.dart';

@JsonSerializable()
class DuplicateEnvelopeName {
  const DuplicateEnvelopeName({required this.privateTag, required this.name});

  factory DuplicateEnvelopeName.fromJson(Map<String, Object?> json) =>
      _$DuplicateEnvelopeNameFromJson(json);

  @JsonKey(name: '_tag')
  final DuplicateEnvelopeNameTag privateTag;
  final String name;

  Map<String, Object?> toJson() => _$DuplicateEnvelopeNameToJson(this);
}
