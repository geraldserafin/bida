// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'log_entry_not_found_tag.dart';

part 'log_entry_not_found.g.dart';

@JsonSerializable()
class LogEntryNotFound {
  const LogEntryNotFound({required this.privateTag, required this.id});

  factory LogEntryNotFound.fromJson(Map<String, Object?> json) =>
      _$LogEntryNotFoundFromJson(json);

  @JsonKey(name: '_tag')
  final LogEntryNotFoundTag privateTag;
  final String id;

  Map<String, Object?> toJson() => _$LogEntryNotFoundToJson(this);
}
