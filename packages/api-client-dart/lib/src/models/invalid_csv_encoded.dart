// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'invalid_csv_encoded_tag.dart';

part 'invalid_csv_encoded.g.dart';

@JsonSerializable()
class InvalidCsvEncoded {
  const InvalidCsvEncoded({
    required this.privateTag,
    required this.line,
    required this.reason,
  });

  factory InvalidCsvEncoded.fromJson(Map<String, Object?> json) =>
      _$InvalidCsvEncodedFromJson(json);

  @JsonKey(name: '_tag')
  final InvalidCsvEncodedTag privateTag;
  final int line;
  final String reason;

  Map<String, Object?> toJson() => _$InvalidCsvEncodedToJson(this);
}
