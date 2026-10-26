import { randomUUID } from "node:crypto";
import {
  Allocation,
  type AllocationId,
  AllocationRule,
  type AllocationRuleId,
  type Counts,
  type CsvImportResult,
  Envelope,
  type EnvelopeId,
  Expense,
  type ExpenseId,
  type ExportDocument,
  type ImportLegacy,
  type ImportPreview,
  Income,
  type IncomeId,
  InvalidCsv,
  InvalidImport,
  RecurringIncome,
  type RecurringIncomeId,
  RecurringRule,
  type RecurringRuleId,
  type UserId,
} from "@bida/api-contract";
import { Context, DateTime, Effect, Layer } from "effect";
import { SqlClient } from "effect/sql";
import { EnvelopesService } from "../envelopes/envelopes.module.ts";
import { ExpensesService } from "../expenses/expenses.module.ts";
import { type CsvRow, formatCsv, parseAmount, parseCsv } from "./csv.ts";
import { convertLegacy } from "./legacy.ts";
import { type Snapshot, TransferRepository } from "./transfer.repository.ts";

/** Same palette as the mobile app's envelope picker. */
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
  envelopes: snapshot.envelopes.length,
  allocations: snapshot.allocations.length,
  incomes: snapshot.incomes.length,
  expenses: snapshot.expenses.length,
  recurringRules: snapshot.recurringRules.length,
  recurringIncomes: snapshot.recurringIncomes.length,
  allocationRules: snapshot.allocationRules.length,
});

/** Checks that every reference in a snapshot points at something in it. */
const checkIntegrity = (snapshot: Snapshot): string | undefined => {
  const envelopes = new Map(snapshot.envelopes.map((e) => [e.id, e]));
  const ruleIds = new Set(snapshot.recurringRules.map((r) => r.id));

  for (const envelope of snapshot.envelopes) {
    if (envelope.parentId === null) continue;
    const parent = envelopes.get(envelope.parentId);
    if (parent === undefined) {
      return `envelope ${envelope.id} points at an unknown parent`;
    }
    if (parent.parentId !== null) {
      return `envelope ${envelope.id} is deeper than a sub-envelope`;
    }
  }
  for (const rule of snapshot.recurringRules) {
    if (!envelopes.has(rule.envelopeId)) {
      return `recurring rule ${rule.id} points at an unknown envelope`;
    }
  }
  for (const rule of snapshot.allocationRules) {
    if (!envelopes.has(rule.envelopeId)) {
      return `allocation rule ${rule.id} points at an unknown envelope`;
    }
  }
  for (const allocation of snapshot.allocations) {
    if (!envelopes.has(allocation.envelopeId)) {
      return `allocation ${allocation.id} points at an unknown envelope`;
    }
  }
  for (const expense of snapshot.expenses) {
    if (!envelopes.has(expense.envelopeId)) {
      return `expense ${expense.id} points at an unknown envelope`;
    }
    if (expense.recurringId !== null && !ruleIds.has(expense.recurringId)) {
      return `expense ${expense.id} points at an unknown recurring rule`;
    }
  }
  return undefined;
};

/**
 * The document as the data of `userId`: every row gets a new id (ids are
 * global, so a document may come from anyone, or be loaded twice) and the
 * user as its owner.
 */
const adopt = (
  doc: Omit<ExportDocument, "exportedAt" | "version">,
  userId: UserId,
): Snapshot => {
  const owner = userId as UserId;
  const fresh = new Map<string, string>();
  const idOf = <Id extends string>(old: Id): Id => {
    let id = fresh.get(old);
    if (id === undefined) {
      id = randomUUID();
      fresh.set(old, id);
    }
    return id as Id;
  };
  return {
    envelopes: doc.envelopes.map(
      (e) =>
        new Envelope({
          ...e,
          id: idOf(e.id),
          ownerId: owner,
          parentId: e.parentId === null ? null : idOf(e.parentId),
        }),
    ),
    allocations: doc.allocations.map(
      (a) =>
        new Allocation({
          ...a,
          id: idOf<AllocationId>(a.id),
          envelopeId: idOf<EnvelopeId>(a.envelopeId),
          userId: owner,
        }),
    ),
    incomes: doc.incomes.map(
      (i) => new Income({ ...i, id: idOf<IncomeId>(i.id), userId: owner }),
    ),
    expenses: doc.expenses.map(
      (x) =>
        new Expense({
          ...x,
          id: idOf<ExpenseId>(x.id),
          envelopeId: idOf<EnvelopeId>(x.envelopeId),
          createdBy: owner,
          recurringId:
            x.recurringId === null
              ? null
              : idOf<RecurringRuleId>(x.recurringId),
        }),
    ),
    recurringIncomes: doc.recurringIncomes.map(
      (r) =>
        new RecurringIncome({
          ...r,
          id: idOf<RecurringIncomeId>(r.id),
          userId: owner,
        }),
    ),
    allocationRules: doc.allocationRules.map(
      (r) =>
        new AllocationRule({
          ...r,
          id: idOf<AllocationRuleId>(r.id),
          envelopeId: idOf<EnvelopeId>(r.envelopeId),
          userId: owner,
        }),
    ),
    recurringRules: doc.recurringRules.map(
      (r) =>
        new RecurringRule({
          ...r,
          id: idOf<RecurringRuleId>(r.id),
          envelopeId: idOf<EnvelopeId>(r.envelopeId),
          userId: owner,
        }),
    ),
  };
};

const day = (date: DateTime.Utc): string =>
  DateTime.formatIso(date).slice(0, 10);

/** Backup, restore and CSV exchange of the data of the signed-in user. */
export class TransferService extends Context.Service<
  TransferService,
  {
    export(userId: UserId): Effect.Effect<ExportDocument>;
    previewImport(
      userId: UserId,
      doc: ExportDocument,
    ): Effect.Effect<ImportPreview>;
    /** Replaces the user's data with the document. */
    importDocument(
      userId: UserId,
      doc: ExportDocument,
    ): Effect.Effect<Counts, InvalidImport>;
    /** Replaces the user's data with a converted backup of the offline app. */
    importLegacy(
      userId: UserId,
      input: ImportLegacy,
    ): Effect.Effect<Counts, InvalidImport>;
    exportCsv(userId: UserId): Effect.Effect<string>;
    importCsv(
      userId: UserId,
      text: string,
    ): Effect.Effect<CsvImportResult, InvalidCsv>;
  }
>()("bida/transfer/TransferService") {
  static readonly layer = Layer.effect(
    TransferService,
    Effect.gen(function* () {
      const repo = yield* TransferRepository;
      const envelopes = yield* EnvelopesService;
      const expenses = yield* ExpensesService;
      const sql = yield* SqlClient.SqlClient;

      const exportDocument = Effect.fn("TransferService.export")(function* (
        userId: UserId,
      ) {
        return {
          version: 2 as const,
          exportedAt: yield* DateTime.now,
          ...(yield* repo.snapshot(userId)),
        };
      });

      const previewImport = Effect.fn("TransferService.previewImport")(
        function* (userId: UserId, doc: ExportDocument) {
          return {
            incoming: countsOf(doc),
            current: yield* repo.counts(userId),
          };
        },
      );

      // all or nothing: the transaction rolls back when anything is refused
      const restore = Effect.fn("TransferService.restore")(function* (
        userId: UserId,
        snapshot: Snapshot,
      ) {
        const problem = checkIntegrity(snapshot);
        if (problem !== undefined)
          return yield* new InvalidImport({ reason: problem });
        yield* repo.replaceAll(userId, snapshot).pipe(
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

      const importDocument = (userId: UserId, doc: ExportDocument) =>
        restore(userId, adopt(doc, userId));

      const importLegacy = Effect.fn("TransferService.importLegacy")(function* (
        userId: UserId,
        input: ImportLegacy,
      ) {
        const converted = yield* convertLegacy(
          input,
          userId,
          yield* DateTime.now,
        ).pipe(
          // the model classes refuse values the API would not accept either
          Effect.catchDefect(() =>
            Effect.fail(
              new InvalidImport({
                reason: "the backup contains values this API does not accept",
              }),
            ),
          ),
        );
        return yield* restore(userId, converted);
      });

      const exportCsv = Effect.fn("TransferService.exportCsv")(function* (
        userId: UserId,
      ) {
        // the user's own expenses, also in envelopes they share
        const rows = (yield* repo.csvRows(userId)).map((row) => ({
          envelope: row.parent ?? row.envelope,
          subenvelope: row.parent === null ? "" : row.envelope,
          amountMinor: row.amountMinor,
          date: day(row.spentAt),
          note: row.note,
        }));
        return formatCsv(rows);
      });

      // Existing expenses of an envelope as "amount|day|note" fingerprints
      const fingerprints = Effect.fn("TransferService.fingerprints")(function* (
        userId: UserId,
        envelopeId: EnvelopeId,
      ) {
        const seen = new Set<string>();
        for (let offset = 0; ; offset += PAGE) {
          const page = yield* expenses
            .list(userId, { envelopeId, limit: PAGE, offset })
            .pipe(Effect.orDie);
          for (const e of page)
            seen.add(`${e.amountMinor}|${day(e.spentAt)}|${e.note ?? ""}`);
          if (page.length < PAGE) return seen;
        }
      });

      const importCsv = Effect.fn("TransferService.importCsv")(function* (
        userId: UserId,
        text: string,
      ) {
        const rows: ReadonlyArray<CsvRow> = yield* parseCsv(text);

        // Everything that can be wrong with the file is found here, before
        // anything is written.
        const prepared: Array<{ row: CsvRow; amountMinor: number }> = [];
        for (const row of rows) {
          const amountMinor = parseAmount(row.amount);
          if (amountMinor === undefined) {
            return yield* new InvalidCsv({
              line: row.line,
              reason: `amount "${row.amount}" is not positive`,
            });
          }
          prepared.push({ row, amountMinor });
        }

        return yield* Effect.gen(function* () {
          const known = new Map<string, Envelope>(
            (yield* envelopes.list(userId)).map((e) => [
              `${e.parentId ?? ""}/${e.name.toLowerCase()}`,
              e,
            ]),
          );
          const seenByEnvelope = new Map<string, Set<string>>();
          let imported = 0;
          let skipped = 0;

          // finds the envelope by name, or creates it
          const envelopeNamed = Effect.fn("TransferService.envelopeNamed")(
            function* (name: string, parentId: EnvelopeId | null) {
              const key = `${parentId ?? ""}/${name.toLowerCase()}`;
              const found = known.get(key);
              if (found !== undefined) return found;
              const created = yield* envelopes
                .create(userId, {
                  parentId,
                  name,
                  color: PALETTE[known.size % PALETTE.length] ?? "#22C55E",
                  icon: null,
                })
                .pipe(Effect.orDie);
              known.set(key, created);
              return created;
            },
          );

          for (const { row, amountMinor } of prepared) {
            const top = yield* envelopeNamed(row.envelope, null);
            const target =
              row.subenvelope === ""
                ? top
                : yield* envelopeNamed(row.subenvelope, top.id);

            let seen = seenByEnvelope.get(target.id);
            if (seen === undefined) {
              seen = yield* fingerprints(userId, target.id);
              seenByEnvelope.set(target.id, seen);
            }
            const fingerprint = `${amountMinor}|${row.date}|${row.note}`;
            if (seen.has(fingerprint)) {
              skipped++;
              continue;
            }
            seen.add(fingerprint);

            yield* expenses
              .create(userId, {
                envelopeId: target.id,
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
