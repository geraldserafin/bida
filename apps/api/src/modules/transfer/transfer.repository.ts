import {
  Allocation,
  type Counts,
  Envelope,
  Expense,
  Income,
  RecurringRule,
} from "@bida/api-contract";
import { Context, Effect, Layer, Schema } from "effect";
import { SqlClient, type SqlError, SqlSchema } from "effect/sql";

/** Everything a user stores, in the shape of the model classes. */
export interface Snapshot {
  readonly envelopes: ReadonlyArray<Envelope>;
  readonly allocations: ReadonlyArray<Allocation>;
  readonly incomes: ReadonlyArray<Income>;
  readonly expenses: ReadonlyArray<Expense>;
  readonly recurringRules: ReadonlyArray<RecurringRule>;
}

/**
 * Whole-user reads and writes for backup and restore. This is the one place
 * that touches every module's tables on purpose: a snapshot has to keep
 * timestamps and set ids, which the modules' services do not let you do.
 */
export class TransferRepository extends Context.Service<
  TransferRepository,
  {
    snapshot(userId: string): Effect.Effect<Snapshot>;
    counts(userId: string): Effect.Effect<Counts>;
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
          FROM envelopes WHERE owner_id = $1 ORDER BY (parent_id IS NOT NULL), created_at, id`,
      );
      const allocations = selectAll(
        Allocation,
        `SELECT a.id, a.envelope_id, a.user_id, a.amount_minor::float8 AS amount_minor,
          a.made_on::text AS made_on, a.note, a.created_at, a.updated_at
          FROM allocations a JOIN envelopes e ON e.id = a.envelope_id
          WHERE e.owner_id = $1 ORDER BY a.made_on, a.created_at, a.id`,
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
          WHERE e.owner_id = $1 ORDER BY x.spent_at, x.id`,
      );
      const recurringRules = selectAll(
        RecurringRule,
        `SELECT id, user_id, envelope_id, amount_minor::float8 AS amount_minor,
          frequency, note, active, created_at, updated_at
          FROM recurring_rules WHERE user_id = $1 ORDER BY created_at, id`,
      );

      const countRows = SqlSchema.findOne({
        Request: Schema.String,
        Result: Schema.Struct({
          envelopes: Schema.Number,
          allocations: Schema.Number,
          incomes: Schema.Number,
          expenses: Schema.Number,
          recurringRules: Schema.Number,
        }),
        execute: (userId) => sql`SELECT
          (SELECT count(*) FROM envelopes WHERE owner_id = ${userId})::int AS envelopes,
          (SELECT count(*) FROM allocations a JOIN envelopes e ON e.id = a.envelope_id
            WHERE e.owner_id = ${userId})::int AS allocations,
          (SELECT count(*) FROM incomes WHERE user_id = ${userId})::int AS incomes,
          (SELECT count(*) FROM expenses x JOIN envelopes e ON e.id = x.envelope_id
            WHERE e.owner_id = ${userId})::int AS expenses,
          (SELECT count(*) FROM recurring_rules WHERE user_id = ${userId})::int AS recurring_rules`,
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

      return TransferRepository.of({
        snapshot: (userId) =>
          Effect.all({
            envelopes: envelopes(userId),
            allocations: allocations(userId),
            incomes: incomes(userId),
            expenses: expenses(userId),
            recurringRules: recurringRules(userId),
          }).pipe(Effect.orDie, Effect.withSpan("TransferRepository.snapshot")),
        counts: (userId) => countRows(userId).pipe(Effect.orDie),
        replaceAll: (userId, snapshot) =>
          Effect.gen(function* () {
            // envelopes take their sub-envelopes, members, allocations,
            // expenses and rules with them
            yield* sql`DELETE FROM envelopes WHERE owner_id = ${userId}`;
            yield* sql`DELETE FROM incomes WHERE user_id = ${userId}`;
            yield* sql`DELETE FROM recurring_rules WHERE user_id = ${userId}`;
            // parents first
            yield* insertEnvelopes(snapshot.envelopes);
            yield* sql`
              INSERT INTO envelope_members (envelope_id, user_id, role)
              SELECT id, owner_id, 'owner' FROM envelopes
              WHERE owner_id = ${userId} AND parent_id IS NULL`;
            yield* insertIncomes(snapshot.incomes);
            yield* insertAllocations(snapshot.allocations);
            yield* insertRules(snapshot.recurringRules);
            yield* insertExpenses(snapshot.expenses);
          }).pipe(Effect.withSpan("TransferRepository.replaceAll")),
      });
    }),
  );
}
