import { Schema } from "effect";
import {
  HttpApiEndpoint,
  HttpApiGroup,
  HttpApiSchema,
  OpenApi,
} from "effect/http-api";
import { InvalidCsv, InvalidImport } from "./transfer.errors.ts";
import {
  Counts,
  CsvImportResult,
  ExportDocument,
  ImportLegacy,
  ImportPreview,
} from "./transfer.model.ts";

const Csv = Schema.String.pipe(
  HttpApiSchema.asText({ contentType: "text/csv" }),
);

export class TransferApi extends HttpApiGroup.make("transfer")
  .add(
    HttpApiEndpoint.get("export", "/export", {
      success: ExportDocument,
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Export all data",
        description: "A full snapshot as JSON, with ids and timestamps.",
      }),
    ),
    HttpApiEndpoint.post("previewImport", "/import/preview", {
      payload: ExportDocument,
      success: ImportPreview,
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Preview an import",
        description:
          "Row counts of the document next to the current data. Changes nothing.",
      }),
    ),
    HttpApiEndpoint.post("import", "/import", {
      payload: ExportDocument,
      success: Counts,
      error: InvalidImport,
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Import a snapshot",
        description:
          "Replaces ALL current data with the document, in one transaction.",
      }),
    ),
    HttpApiEndpoint.post("importLegacy", "/import/legacy", {
      payload: ImportLegacy,
      success: Counts,
      error: InvalidImport,
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Import a backup of the offline app",
        description:
          "Converts the old local format (integer ids, amounts in zloty) and replaces ALL current data.",
      }),
    ),
    HttpApiEndpoint.get("exportCsv", "/export.csv", {
      success: Csv,
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Export expenses as CSV",
        description: "Columns: Period, Category, Amount, Date, Note.",
      }),
    ),
    HttpApiEndpoint.post("importCsv", "/import/csv", {
      payload: Csv,
      success: CsvImportResult,
      error: InvalidCsv,
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Import expenses from CSV",
        description:
          "Creates missing periods and categories by name and skips rows that already exist.",
      }),
    ),
  )
  .annotateMerge(OpenApi.annotations({ title: "Transfer" })) {}
