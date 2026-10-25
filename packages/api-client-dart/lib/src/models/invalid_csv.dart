// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'invalid_csv_tag.dart';

part 'invalid_csv.g.dart';

@JsonSerializable()
class InvalidCsv {
  const InvalidCsv({
    required this.privateTag,
    required this.line,
    required this.reason,
  });

  factory InvalidCsv.fromJson(Map<String, Object?> json) =>
      _$InvalidCsvFromJson(json);

  @JsonKey(name: '_tag')
  final InvalidCsvTag privateTag;
  final int line;
  final String reason;

  Map<String, Object?> toJson() => _$InvalidCsvToJson(this);
}
