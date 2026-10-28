import {
  Allocation,
  AllocationRule,
  type Counts,
  Envelope,
  Expense,
  Income,
  RecurringIncome,
  RecurringRule,
} from "@bida/api-contract";
import { Context, Effect, Layer, Schema } from "effect";
import { SqlClient, type SqlError, SqlSchema } from "effect/sql";

export const CsvExpense = Schema.Struct({
  envelope: Schema.String,
  parent: Schema.NullOr(Schema.String),
  amountMinor: Schema.Number,
  spentAt: Schema.DateTimeUtcFromDate,
  note: Schema.NullOr(Schema.String),
});
export type CsvExpense = typeof CsvExpense.Type;

/** Everything a user stores, in the shape of the model classes. */
export interface Snapshot {
  readonly envelopes: ReadonlyArray<Envelope>;
  readonly allocations: ReadonlyArray<Allocation>;
  readonly incomes: ReadonlyArray<Income>;
  readonly expenses: ReadonlyArray<Expense>;
  readonly recurringRules: ReadonlyArray<RecurringRule>;
  readonly recurringIncomes: ReadonlyArray<RecurringIncome>;
  readonly allocationRules: ReadonlyArray<AllocationRule>;
}

/**
 * Whole-user reads and writes for backup and restore. A backup holds the
 * envelopes that are only the user's (nobody else is a member), with what is in
 * them; shared envelopes are left out of it and are never replaced by an
 * import, because they are not the user's alone.
 *
 * Whole-user reads and writes for backup and restore. This is the one place
 * that touches every module's tables on purpose: a snapshot has to keep
 * timestamps and set ids, which the modules' services do not let you do.
 */
export class TransferRepository extends Context.Service<
  TransferRepository,
  {
    snapshot(userId: string): Effect.Effect<Snapshot>;
    counts(userId: string): Effect.Effect<Counts>;
    /** The user's own expenses, in any envelope they can see. */
    csvRows(userId: string): Effect.Effect<ReadonlyArray<CsvExpense>>;
    /**
     * Deletes the envelopes the user owns (with everything in them), their
     * income and their rules, then inserts the snapshot. Run it inside a
     * transaction so a failure leaves the data untouched.
     */
    replaceAll(
      userId: string,
      snapshot: Snapshot,
    ): Effect.Effect<void, SqlError.SqlError>;
  }
>()("bida/transfer/TransferRepository") {
  static readonly layer = Layer.effect(
    TransferRepository,
    Effect.gen(function* () {
      const sql = yield* SqlClient.SqlClient;

      // the top-level envelopes of which the user is the only member
      const alone = `(SELECT envelope_id FROM envelope_members
        GROUP BY envelope_id HAVING count(*) = 1 AND bool_and(user_id = $1))`;

      // bigint comes back from pg as a string and date as a Date, so cast both
      const selectAll = <S extends Schema.Constraint>(
        Result: S,
        query: string,
      ) =>
        SqlSchema.findAll({
          Request: Schema.String,
          Result,
          execute: (userId) => sql.unsafe(query, [userId]),
        });

      const envelopes = selectAll(
        Envelope,
        `SELECT id, owner_id, parent_id, name, color, icon, created_at, updated_at
          FROM envelopes WHERE COALESCE(parent_id, id) IN ${alone}
          ORDER BY (parent_id IS NOT NULL), created_at, id`,
      );
      const allocations = selectAll(
        Allocation,
        `SELECT a.id, a.envelope_id, a.user_id, a.amount_minor::float8 AS amount_minor,
          a.made_on::text AS made_on, a.note, a.created_at, a.updated_at
          FROM allocations a JOIN envelopes e ON e.id = a.envelope_id
          WHERE COALESCE(e.parent_id, e.id) IN ${alone}
          ORDER BY a.made_on, a.created_at, a.id`,
      );
      const incomes = selectAll(
        Income,
        `SELECT id, user_id, amount_minor::float8 AS amount_minor,
          received_on::text AS received_on, note, created_at, updated_at
          FROM incomes WHERE user_id = $1 ORDER BY received_on, created_at, id`,
      );
      const expenses = selectAll(
        Expense,
        `SELECT x.id, x.envelope_id, x.created_by, x.amount_minor::float8 AS amount_minor,
          x.spent_at, x.note, x.recurring_id, x.created_at, x.updated_at
          FROM expenses x JOIN envelopes e ON e.id = x.envelope_id
          WHERE COALESCE(e.parent_id, e.id) IN ${alone}
          ORDER BY x.spent_at, x.id`,
      );
      const recurringRules = selectAll(
        RecurringRule,
        `SELECT id, user_id, envelope_id, amount_minor::float8 AS amount_minor,
          frequency, note, active, created_at, updated_at
          FROM recurring_rules r
          WHERE r.user_id = $1 AND r.envelope_id IN (
            SELECT id FROM envelopes WHERE COALESCE(parent_id, id) IN ${alone})
          ORDER BY r.created_at, r.id`,
      );

      const recurringIncomes = selectAll(
        RecurringIncome,
        `SELECT id, user_id, amount_minor::float8 AS amount_minor, day_of_month,
          note, active, created_at, updated_at
          FROM recurring_incomes WHERE user_id = $1 ORDER BY created_at, id`,
      );
      const allocationRules = selectAll(
        AllocationRule,
        `SELECT id, user_id, envelope_id, amount_minor::float8 AS amount_minor,
          day_of_month, note, active, created_at, updated_at
          FROM allocation_rules r
          WHERE r.user_id = $1 AND r.envelope_id IN (
            SELECT id FROM envelopes WHERE COALESCE(parent_id, id) IN ${alone})
          ORDER BY r.created_at, r.id`,
      );

      const csv = SqlSchema.findAll({
        Request: Schema.String,
        Result: CsvExpense,
        execute: (userId) =>
          sql`SELECT e.name AS envelope, p.name AS parent, x.amount_minor::float8 AS amount_minor,
              x.spent_at, x.note
            FROM expenses x
            JOIN envelopes e ON e.id = x.envelope_id
            LEFT JOIN envelopes p ON p.id = e.parent_id
            WHERE x.created_by = ${userId}
            ORDER BY x.spent_at DESC, x.id`,
      });

      // One bulk insert per table, skipped when there is nothing to insert
      const insertRows = <S extends Schema.Constraint>(
        table: string,
        Row: S,
      ) => {
        const insert = SqlSchema.void({
          Request: Schema.NonEmptyArray(Row),
          execute: (rows) =>
            sql`INSERT INTO ${sql(table)} ${sql.insert(rows as never)}`,
        });
        return (rows: ReadonlyArray<S["Type"]>) =>
          rows.length === 0
            ? Effect.void
            : insert(rows as never).pipe(
                Effect.catchTag("SchemaError", Effect.die),
              );
      };
      const insertEnvelopes = insertRows("envelopes", Envelope);
      const insertAllocations = insertRows("allocations", Allocation);
      const insertIncomes = insertRows("incomes", Income);
      const insertExpenses = insertRows("expenses", Expense);
      const insertRules = insertRows("recurring_rules", RecurringRule);
      const insertRecurringIncomes = insertRows(
        "recurring_incomes",
        RecurringIncome,
      );
      const insertAllocationRules = insertRows(
        "allocation_rules",
        AllocationRule,
      );

      return TransferRepository.of({
        snapshot: (userId) =>
          Effect.all({
            envelopes: envelopes(userId),
            allocations: allocations(userId),
            incomes: incomes(userId),
            expenses: expenses(userId),
            recurringRules: recurringRules(userId),
            recurringIncomes: recurringIncomes(userId),
            allocationRules: allocationRules(userId),
          }).pipe(Effect.orDie, Effect.withSpan("TransferRepository.snapshot")),
        counts: (userId) =>
          Effect.all({
            envelopes: envelopes(userId),
            allocations: allocations(userId),
            incomes: incomes(userId),
            expenses: expenses(userId),
            recurringRules: recurringRules(userId),
            recurringIncomes: recurringIncomes(userId),
            allocationRules: allocationRules(userId),
          }).pipe(
            Effect.map((rows) => ({
              envelopes: rows.envelopes.length,
              allocations: rows.allocations.length,
              incomes: rows.incomes.length,
              expenses: rows.expenses.length,
              recurringRules: rows.recurringRules.length,
              recurringIncomes: rows.recurringIncomes.length,
              allocationRules: rows.allocationRules.length,
            })),
            Effect.orDie,
          ),
        csvRows: (userId) => csv(userId).pipe(Effect.orDie),
        replaceAll: (userId, snapshot) =>
          Effect.gen(function* () {
            // envelopes take their sub-envelopes, members, allocations,
            // expenses and rules with them; the shared ones are not touched
            yield* sql.unsafe(
              `DELETE FROM envelopes WHERE COALESCE(parent_id, id) IN ${alone}`,
              [userId],
            );
            yield* sql`DELETE FROM incomes WHERE user_id = ${userId}`;
            yield* sql`DELETE FROM recurring_incomes WHERE user_id = ${userId}`;
            // parents first
            yield* insertEnvelopes(snapshot.envelopes);
            const topLevel = snapshot.envelopes
              .filter((envelope) => envelope.parentId === null)
              .map((envelope) => envelope.id);
            if (topLevel.length > 0) {
              yield* sql`INSERT INTO envelope_members (envelope_id, user_id, role)
                SELECT id, ${userId}, 'owner' FROM envelopes
                WHERE ${sql.in("id", topLevel)}`;
            }
            yield* insertRecurringIncomes(snapshot.recurringIncomes);
            yield* insertIncomes(snapshot.incomes);
            yield* insertAllocationRules(snapshot.allocationRules);
            yield* insertAllocations(snapshot.allocations);
            yield* insertRules(snapshot.recurringRules);
            yield* insertExpenses(snapshot.expenses);
          }).pipe(Effect.withSpan("TransferRepository.replaceAll")),
      });
    }),
  );
}
