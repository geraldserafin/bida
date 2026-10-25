// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'counts.dart';

part 'import_preview.g.dart';

@JsonSerializable()
class ImportPreview {
  const ImportPreview({required this.incoming, required this.current});

  factory ImportPreview.fromJson(Map<String, Object?> json) =>
      _$ImportPreviewFromJson(json);

  final Counts incoming;
  final Counts current;

  Map<String, Object?> toJson() => _$ImportPreviewToJson(this);
}
