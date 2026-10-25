// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'csv_import_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CsvImportResult _$CsvImportResultFromJson(Map<String, dynamic> json) =>
    CsvImportResult(
      imported: (json['imported'] as num).toInt(),
      skipped: (json['skipped'] as num).toInt(),
    );

Map<String, dynamic> _$CsvImportResultToJson(CsvImportResult instance) =>
    <String, dynamic>{
      'imported': instance.imported,
      'skipped': instance.skipped,
    };
