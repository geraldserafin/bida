// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'invalid_import_tag.dart';

part 'invalid_import.g.dart';

@JsonSerializable()
class InvalidImport {
  const InvalidImport({required this.privateTag, required this.reason});

  factory InvalidImport.fromJson(Map<String, Object?> json) =>
      _$InvalidImportFromJson(json);

  @JsonKey(name: '_tag')
  final InvalidImportTag privateTag;
  final String reason;

  Map<String, Object?> toJson() => _$InvalidImportToJson(this);
}
