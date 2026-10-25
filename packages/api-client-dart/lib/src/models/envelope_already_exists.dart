// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'envelope_already_exists_tag.dart';

part 'envelope_already_exists.g.dart';

@JsonSerializable()
class EnvelopeAlreadyExists {
  const EnvelopeAlreadyExists({
    required this.privateTag,
    required this.periodId,
    required this.categoryId,
  });

  factory EnvelopeAlreadyExists.fromJson(Map<String, Object?> json) =>
      _$EnvelopeAlreadyExistsFromJson(json);

  @JsonKey(name: '_tag')
  final EnvelopeAlreadyExistsTag privateTag;
  final String periodId;
  final String categoryId;

  Map<String, Object?> toJson() => _$EnvelopeAlreadyExistsToJson(this);
}
