import {
  type Counts,
  type CsvImportResult,
  DEFAULT_CURRENCY,
  type EnvelopeId,
  type ExportDocument,
  exponentOf,
  type ImportLegacy,
  type ImportPreview,
  InvalidCsv,
  InvalidImport,
  type PeriodId,
} from "@bida/api-contract";
import { Context, DateTime, Effect, Layer } from "effect";
import { SqlClient } from "effect/sql";
import { BudgetsService } from "../budgets/budgets.module.ts";
import { CategoriesService } from "../categories/categories.module.ts";
import { ExpensesService } from "../expenses/expenses.module.ts";
import { type CsvRow, formatCsv, parseAmount, parseCsv } from "./csv.ts";
import { convertLegacy } from "./legacy.ts";
import { type Snapshot, TransferRepository } from "./transfer.repository.ts";

/** Same palette as the mobile app's category picker. */
const PALETTE = [
  "#22C55E",
  "#EC4899",
  "#6366F1",
  "#14B8A6",
  "#F59E0B",
  "#EF4444",
  "#A855F7",
  "#3B82F6",
  "#F97316",
  "#10B981",
  "#EAB308",
  "#8B5CF6",
];

const PAGE = 200;

const countsOf = (snapshot: Snapshot): Counts => ({
  categories: snapshot.categories.length,
  periods: snapshot.periods.length,
  envelopes: snapshot.envelopes.length,
  expenses: snapshot.expenses.length,
  recurringRules: snapshot.recurringRules.length,
});

/** Checks that every reference in a snapshot points at something in it. */
const checkIntegrity = (snapshot: Snapshot): string | undefined => {
  const categoryIds = new Set(snapshot.categories.map((c) => c.id));
  const periodIds = new Set(snapshot.periods.map((p) => p.id));
  const ruleIds = new Set(snapshot.recurringRules.map((r) => r.id));
  const envelopePeriod = new Map(
    snapshot.envelopes.map((e) => [e.id, e.periodId]),
  );

  for (const rule of snapshot.recurringRules) {
    if (!categoryIds.has(rule.categoryId)) {
      return `recurring rule ${rule.id} points at an unknown category`;
    }
  }
  const seen = new Set<string>();
  for (const envelope of snapshot.envelopes) {
    if (!periodIds.has(envelope.periodId)) {
      return `envelope ${envelope.id} points at an unknown period`;
    }
    if (!categoryIds.has(envelope.categoryId)) {
      return `envelope ${envelope.id} points at an unknown category`;
    }
    const key = `${envelope.periodId}/${envelope.categoryId}`;
    if (seen.has(key))
      return `period ${envelope.periodId} has two envelopes for category ${envelope.categoryId}`;
    seen.add(key);
  }
  for (const expense of snapshot.expenses) {
    const period = envelopePeriod.get(expense.envelopeId);
    if (period === undefined) {
      return `expense ${expense.id} points at an unknown envelope`;
    }
    if (period !== expense.periodId) {
      return `expense ${expense.id} has a different period than its envelope`;
    }
    if (expense.recurringId !== null && !ruleIds.has(expense.recurringId)) {
      return `expense ${expense.id} points at an unknown recurring rule`;
    }
  }
  return undefined;
};

const snapshotOf = (doc: Omit<ExportDocument, "exportedAt">): Snapshot => doc;

const day = (date: DateTime.Utc): string =>
  DateTime.formatIso(date).slice(0, 10);

/** Backup, restore and CSV exchange of the whole data set. */
export class TransferService extends Context.Service<
  TransferService,
  {
    export: Effect.Effect<ExportDocument>;
    previewImport(doc: ExportDocument): Effect.Effect<ImportPreview>;
    /** Replaces all data with the document. */
    importDocument(doc: ExportDocument): Effect.Effect<Counts, InvalidImport>;
    /** Replaces all data with a converted backup of the offline app. */
    importLegacy(input: ImportLegacy): Effect.Effect<Counts, InvalidImport>;
    exportCsv: Effect.Effect<string>;
    importCsv(text: string): Effect.Effect<CsvImportResult, InvalidCsv>;
  }
>()("bida/transfer/TransferService") {
  static readonly layer = Layer.effect(
    TransferService,
    Effect.gen(function* () {
      const repo = yield* TransferRepository;
      const categories = yield* CategoriesService;
      const budgets = yield* BudgetsService;
      const expenses = yield* ExpensesService;
      const sql = yield* SqlClient.SqlClient;

      const exportDocument = Effect.gen(function* () {
        return {
          version: 1 as const,
          exportedAt: yield* DateTime.now,
          ...(yield* repo.snapshot),
        };
      }).pipe(Effect.withSpan("TransferService.export"));

      const previewImport = Effect.fn("TransferService.previewImport")(
        function* (doc: ExportDocument) {
          return {
            incoming: countsOf(snapshotOf(doc)),
            current: yield* repo.counts,
          };
        },
      );

      // all or nothing: the transaction rolls back when anything is refused
      const restore = Effect.fn("TransferService.restore")(function* (
        snapshot: Snapshot,
      ) {
        const problem = checkIntegrity(snapshot);
        if (problem !== undefined)
          return yield* new InvalidImport({ reason: problem });
        yield* repo.replaceAll(snapshot).pipe(
          sql.withTransaction,
          Effect.catchTag("SqlError", (error) =>
            error.reason._tag === "ConstraintError" ||
            error.reason._tag === "UniqueViolation"
              ? Effect.fail(
                  new InvalidImport({
                    reason: "the data violates a database constraint",
                  }),
                )
              : Effect.die(error),
          ),
        );
        return countsOf(snapshot);
      });

      const importDocument = (doc: ExportDocument) => restore(snapshotOf(doc));

      const importLegacy = Effect.fn("TransferService.importLegacy")(function* (
        input: ImportLegacy,
      ) {
        const converted = yield* convertLegacy(input, yield* DateTime.now);
        return yield* restore(snapshotOf(converted));
      });

      const exportCsv = Effect.gen(function* () {
        const snapshot = yield* repo.snapshot;
        const periodName = new Map(snapshot.periods.map((p) => [p.id, p.name]));
        const periodCurrency = new Map(
          snapshot.periods.map((p) => [p.id, p.currency]),
        );
        const categoryName = new Map(
          snapshot.categories.map((c) => [c.id, c.name]),
        );
        const envelopeCategory = new Map(
          snapshot.envelopes.map((e) => [e.id, e.categoryId]),
        );
        const rows = [...snapshot.expenses]
          .sort(
            (a, b) => b.spentAt.epochMilliseconds - a.spentAt.epochMilliseconds,
          )
          .map((expense) => ({
            period: periodName.get(expense.periodId) ?? "",
            category:
              categoryName.get(
                envelopeCategory.get(expense.envelopeId) ?? ("" as never),
              ) ?? "",
            amountMinor: expense.amountMinor,
            currency: periodCurrency.get(expense.periodId) ?? DEFAULT_CURRENCY,
            date: day(expense.spentAt),
            note: expense.note,
          }));
        return formatCsv(rows);
      }).pipe(Effect.withSpan("TransferService.exportCsv"));

      // Existing expenses of an envelope as "amount|day|note" fingerprints
      const fingerprints = Effect.fn("TransferService.fingerprints")(function* (
        periodId: PeriodId,
        envelopeId: NonNullable<
          Parameters<typeof expenses.listForPeriod>[1]["envelopeId"]
        >,
      ) {
        const seen = new Set<string>();
        for (let offset = 0; ; offset += PAGE) {
          const page = yield* expenses
            .listForPeriod(periodId, { envelopeId, limit: PAGE, offset })
            .pipe(Effect.orDie);
          for (const e of page)
            seen.add(`${e.amountMinor}|${day(e.spentAt)}|${e.note ?? ""}`);
          if (page.length < PAGE) return seen;
        }
      });

      const monthOf = (date: string) => {
        const [y, m] = date.split("-").map(Number) as [number, number];
        const last = new Date(Date.UTC(y, m, 0)).getUTCDate();
        const mm = String(m).padStart(2, "0");
        return {
          startDate: `${y}-${mm}-01`,
          endDate: `${y}-${mm}-${String(last).padStart(2, "0")}`,
        };
      };

      const importCsv = Effect.fn("TransferService.importCsv")(function* (
        text: string,
      ) {
        const rows: ReadonlyArray<CsvRow> = yield* parseCsv(text);

        // Everything that can be wrong with the file is found here, before
        // anything is written: amounts depend on the currency of the period.
        const existing = new Map(
          (yield* budgets.listPeriods).map(
            (p) => [p.name, p.currency] as const,
          ),
        );
        const currencyOf = new Map(existing);
        const prepared: Array<{ row: CsvRow; amountMinor: number }> = [];
        for (const row of rows) {
          const currency =
            currencyOf.get(row.period) ?? row.currency ?? DEFAULT_CURRENCY;
          currencyOf.set(row.period, currency);
          if (row.currency !== undefined && row.currency !== currency) {
            return yield* new InvalidCsv({
              line: row.line,
              reason: `period "${row.period}" is in ${currency}, not ${row.currency}`,
            });
          }
          const amountMinor = parseAmount(row.amount, exponentOf(currency));
          if (amountMinor === undefined) {
            return yield* new InvalidCsv({
              line: row.line,
              reason: `amount "${row.amount}" is not positive in ${currency}`,
            });
          }
          prepared.push({ row, amountMinor });
        }

        return yield* Effect.gen(function* () {
          const periods = new Map(
            (yield* budgets.listPeriods).map((p) => [p.name, p] as const),
          );
          const knownCategories = new Map(
            (yield* categories.list).map(
              (c) => [c.name.toLowerCase(), c] as const,
            ),
          );
          const envelopes = new Map<string, EnvelopeId>();
          const seenByEnvelope = new Map<string, Set<string>>();
          let imported = 0;
          let skipped = 0;

          for (const { row, amountMinor } of prepared) {
            let period = periods.get(row.period);
            if (period === undefined) {
              const created = yield* budgets
                .createPeriod({
                  name: row.period,
                  ...monthOf(row.date),
                  incomeMinor: 0,
                  currency: currencyOf.get(row.period) ?? DEFAULT_CURRENCY,
                  envelopes: [],
                })
                .pipe(Effect.orDie);
              period = created.period;
              periods.set(row.period, period);
            }
            let category = knownCategories.get(row.category.toLowerCase());
            if (category === undefined) {
              category = yield* categories.create({
                name: row.category,
                color:
                  PALETTE[knownCategories.size % PALETTE.length] ?? "#22C55E",
                icon: null,
              });
              knownCategories.set(row.category.toLowerCase(), category);
            }

            const envelopeKey = `${period.id}/${category.id}`;
            let envelopeId = envelopes.get(envelopeKey);
            if (envelopeId === undefined) {
              const detail = yield* budgets
                .getPeriod(period.id)
                .pipe(Effect.orDie);
              const found = detail.envelopes.find(
                (e) => e.categoryId === category.id,
              );
              envelopeId = (
                found ??
                (yield* budgets
                  .addEnvelope(period.id, {
                    categoryId: category.id,
                    plannedMinor: 0,
                  })
                  .pipe(Effect.orDie))
              ).id;
              envelopes.set(envelopeKey, envelopeId);
            }

            let seen = seenByEnvelope.get(envelopeKey);
            if (seen === undefined) {
              seen = yield* fingerprints(period.id, envelopeId);
              seenByEnvelope.set(envelopeKey, seen);
            }
            const fingerprint = `${amountMinor}|${row.date}|${row.note}`;
            if (seen.has(fingerprint)) {
              skipped++;
              continue;
            }
            seen.add(fingerprint);

            yield* expenses
              .create({
                envelopeId,
                amountMinor,
                spentAt: DateTime.makeUnsafe(`${row.date}T00:00:00Z`),
                note: row.note === "" ? null : row.note,
              })
              .pipe(Effect.orDie);
            imported++;
          }
          return { imported, skipped };
        }).pipe(sql.withTransaction, Effect.orDie);
      });

      return TransferService.of({
        export: exportDocument,
        previewImport,
        importDocument,
        importLegacy,
        exportCsv,
        importCsv,
      });
    }),
  );
}
