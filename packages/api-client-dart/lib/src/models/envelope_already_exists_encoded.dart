// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'envelope_already_exists_encoded_tag.dart';

part 'envelope_already_exists_encoded.g.dart';

@JsonSerializable()
class EnvelopeAlreadyExistsEncoded {
  const EnvelopeAlreadyExistsEncoded({
    required this.privateTag,
    required this.periodId,
    required this.categoryId,
  });

  factory EnvelopeAlreadyExistsEncoded.fromJson(Map<String, Object?> json) =>
      _$EnvelopeAlreadyExistsEncodedFromJson(json);

  @JsonKey(name: '_tag')
  final EnvelopeAlreadyExistsEncodedTag privateTag;
  final String periodId;
  final String categoryId;

  Map<String, Object?> toJson() => _$EnvelopeAlreadyExistsEncodedToJson(this);
}
