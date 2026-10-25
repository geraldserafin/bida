// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/counts.dart';
import '../models/csv_import_result.dart';
import '../models/export_document.dart';
import '../models/import_legacy.dart';
import '../models/import_preview.dart';

part 'transfer_client.g.dart';

@RestApi()
abstract class TransferClient {
  factory TransferClient(Dio dio, {String? baseUrl}) = _TransferClient;

  /// Export all data.
  ///
  /// A full snapshot as JSON, with ids and timestamps.
  @GET('/export')
  Future<ExportDocument> transferExport();

  /// Preview an import.
  ///
  /// Row counts of the document next to the current data. Changes nothing.
  @POST('/import/preview')
  Future<ImportPreview> transferPreviewImport({
    @Body() required ExportDocument body,
  });

  /// Import a snapshot.
  ///
  /// Replaces ALL current data with the document, in one transaction. Owners of the space only.
  @POST('/import')
  Future<Counts> transferImport({@Body() required ExportDocument body});

  /// Import a backup of the offline app.
  ///
  /// Converts the old local format (integer ids, amounts in zloty) and replaces ALL current data. Owners of the space only.
  @POST('/import/legacy')
  Future<Counts> transferImportLegacy({@Body() required ImportLegacy body});

  /// Export expenses as CSV.
  ///
  /// Columns: Period, Category, Amount, Date, Note.
  @GET('/export.csv')
  Future<String> transferExportCsv();

  /// Import expenses from CSV.
  ///
  /// Creates missing periods and categories by name and skips rows that already exist.
  @POST('/import/csv')
  Future<CsvImportResult> transferImportCsv({@Body() required String body});
}
