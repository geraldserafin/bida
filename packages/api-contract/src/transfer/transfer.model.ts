import { Schema } from "effect";
import { EnvelopeJson, PeriodJson } from "../budgets/index.ts";
import { CategoryJson } from "../categories/index.ts";
import { ExpenseJson } from "../expenses/index.ts";
import { RecurringRuleJson } from "../recurring/index.ts";

/** A full snapshot of the data. Exported and imported as one JSON document. */
export const ExportDocument = Schema.Struct({
  version: Schema.Literal(1),
  exportedAt: Schema.DateTimeUtcFromString,
  categories: Schema.Array(CategoryJson).check(Schema.isMaxLength(1_000)),
  periods: Schema.Array(PeriodJson).check(Schema.isMaxLength(10_000)),
  envelopes: Schema.Array(EnvelopeJson).check(Schema.isMaxLength(100_000)),
  expenses: Schema.Array(ExpenseJson).check(Schema.isMaxLength(200_000)),
  recurringRules: Schema.Array(RecurringRuleJson).check(
    Schema.isMaxLength(1_000),
  ),
}).annotate({ identifier: "ExportDocument" });
export type ExportDocument = typeof ExportDocument.Type;

/** Row counts per kind of data. */
export const Counts = Schema.Struct({
  categories: Schema.Int,
  periods: Schema.Int,
  envelopes: Schema.Int,
  expenses: Schema.Int,
  recurringRules: Schema.Int,
}).annotate({ identifier: "Counts" });
export type Counts = typeof Counts.Type;

/** What an import would replace, to confirm before applying it. */
export const ImportPreview = Schema.Struct({
  incoming: Counts,
  current: Counts,
}).annotate({ identifier: "ImportPreview" });
export type ImportPreview = typeof ImportPreview.Type;

/**
 * A backup made by the first, offline version of the mobile app: integer ids,
 * snake_case columns and amounts in zloty as decimals.
 */
export const LegacyBackup = Schema.Struct({
  version: Schema.Int,
  exportedAt: Schema.optional(Schema.String),
  data: Schema.Struct({
    periods: Schema.Array(
      Schema.Struct({
        id: Schema.Int,
        name: Schema.String,
        start_date: Schema.String,
        end_date: Schema.String,
        income: Schema.Number,
      }),
    ),
    categories: Schema.Array(
      Schema.Struct({
        id: Schema.Int,
        name: Schema.String,
        color: Schema.String,
        icon: Schema.NullOr(Schema.String),
      }),
    ),
    recurring_rules: Schema.Array(
      Schema.Struct({
        id: Schema.Int,
        category_id: Schema.Int,
        amount: Schema.Number,
        frequency: Schema.String,
        note: Schema.NullOr(Schema.String),
        active: Schema.Int,
      }),
    ),
    splits: Schema.Array(
      Schema.Struct({
        id: Schema.Int,
        period_id: Schema.Int,
        category_id: Schema.Int,
        planned_amount: Schema.Number,
      }),
    ),
    expenses: Schema.Array(
      Schema.Struct({
        id: Schema.Int,
        split_id: Schema.Int,
        amount: Schema.Number,
        date: Schema.String,
        note: Schema.NullOr(Schema.String),
        recurring_id: Schema.NullOr(Schema.Int),
      }),
    ),
  }),
}).annotate({ identifier: "LegacyBackup" });
export type LegacyBackup = typeof LegacyBackup.Type;

export const ImportLegacy = Schema.Struct({
  backup: LegacyBackup,
  /**
   * IANA time zone the old app's local timestamps were recorded in. Defaults
   * to `Europe/Warsaw`.
   */
  timeZone: Schema.optional(Schema.String),
}).annotate({ identifier: "ImportLegacy" });
export type ImportLegacy = typeof ImportLegacy.Type;

export const CsvImportResult = Schema.Struct({
  imported: Schema.Int,
  /** Rows that were already there (same envelope, amount, day and note). */
  skipped: Schema.Int,
}).annotate({ identifier: "CsvImportResult" });
export type CsvImportResult = typeof CsvImportResult.Type;
