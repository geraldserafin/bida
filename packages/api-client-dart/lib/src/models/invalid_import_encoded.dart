// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'invalid_import_encoded_tag.dart';

part 'invalid_import_encoded.g.dart';

@JsonSerializable()
class InvalidImportEncoded {
  const InvalidImportEncoded({required this.privateTag, required this.reason});

  factory InvalidImportEncoded.fromJson(Map<String, Object?> json) =>
      _$InvalidImportEncodedFromJson(json);

  @JsonKey(name: '_tag')
  final InvalidImportEncodedTag privateTag;
  final String reason;

  Map<String, Object?> toJson() => _$InvalidImportEncodedToJson(this);
}
