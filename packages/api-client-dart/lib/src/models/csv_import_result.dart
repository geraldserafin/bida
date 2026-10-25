// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'csv_import_result.g.dart';

@JsonSerializable()
class CsvImportResult {
  const CsvImportResult({required this.imported, required this.skipped});

  factory CsvImportResult.fromJson(Map<String, Object?> json) =>
      _$CsvImportResultFromJson(json);

  final int imported;
  final int skipped;

  Map<String, Object?> toJson() => _$CsvImportResultToJson(this);
}
