import {
  Category,
  type Counts,
  Envelope,
  Expense,
  Period,
  RecurringRule,
} from "@bida/api-contract";
import { Context, Effect, Layer, Schema } from "effect";
import { SqlClient, type SqlError, SqlSchema } from "effect/sql";

/** Everything the application stores, in the shape of the model classes. */
export interface Snapshot {
  readonly categories: ReadonlyArray<Category>;
  readonly periods: ReadonlyArray<Period>;
  readonly envelopes: ReadonlyArray<Envelope>;
  readonly expenses: ReadonlyArray<Expense>;
  readonly recurringRules: ReadonlyArray<RecurringRule>;
}

/**
 * Whole-database reads and writes for backup and restore. This is the one
 * place that touches every module's tables on purpose: a snapshot has to
 * keep ids and timestamps, which the modules' services do not let you set.
 */
export class TransferRepository extends Context.Service<
  TransferRepository,
  {
    snapshot: Effect.Effect<Snapshot>;
    counts: Effect.Effect<Counts>;
    /**
     * Deletes everything, then inserts the snapshot. Run it inside a
     * transaction so a failure leaves the data untouched.
     */
    replaceAll(snapshot: Snapshot): Effect.Effect<void, SqlError.SqlError>;
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
          Request: Schema.Void,
          Result,
          execute: () => sql.unsafe(query),
        });

      const categories = selectAll(
        Category,
        "SELECT id, name, color, icon, created_at, updated_at FROM categories ORDER BY created_at, id",
      );
      const periods = selectAll(
        Period,
        `SELECT id, name, start_date::text AS start_date, end_date::text AS end_date,
          income_minor::float8 AS income_minor, currency, created_at, updated_at
          FROM periods ORDER BY start_date, created_at, id`,
      );
      const envelopes = selectAll(
        Envelope,
        `SELECT id, period_id, category_id, planned_minor::float8 AS planned_minor,
          created_at, updated_at FROM envelopes ORDER BY created_at, id`,
      );
      const expenses = selectAll(
        Expense,
        `SELECT id, period_id, envelope_id, amount_minor::float8 AS amount_minor,
          original_amount_minor::float8 AS original_amount_minor, original_currency,
          spent_at, note, recurring_id, created_at, updated_at
          FROM expenses ORDER BY spent_at, id`,
      );
      const recurringRules = selectAll(
        RecurringRule,
        `SELECT id, category_id, amount_minor::float8 AS amount_minor, currency, frequency,
          note, active, created_at, updated_at FROM recurring_rules ORDER BY created_at, id`,
      );

      const countRows = SqlSchema.findOne({
        Request: Schema.Void,
        Result: Schema.Struct({
          categories: Schema.Number,
          periods: Schema.Number,
          envelopes: Schema.Number,
          expenses: Schema.Number,
          recurringRules: Schema.Number,
        }),
        execute: () => sql`SELECT
          (SELECT count(*) FROM categories)::int AS categories,
          (SELECT count(*) FROM periods)::int AS periods,
          (SELECT count(*) FROM envelopes)::int AS envelopes,
          (SELECT count(*) FROM expenses)::int AS expenses,
          (SELECT count(*) FROM recurring_rules)::int AS recurring_rules`,
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
      const insertCategories = insertRows("categories", Category);
      const insertPeriods = insertRows("periods", Period);
      const insertRecurringRules = insertRows("recurring_rules", RecurringRule);
      const insertEnvelopes = insertRows("envelopes", Envelope);
      const insertExpenses = insertRows("expenses", Expense);

      return TransferRepository.of({
        snapshot: Effect.all({
          categories: categories(),
          periods: periods(),
          envelopes: envelopes(),
          expenses: expenses(),
          recurringRules: recurringRules(),
        }).pipe(Effect.orDie, Effect.withSpan("TransferRepository.snapshot")),
        counts: countRows().pipe(Effect.orDie),
        replaceAll: (snapshot) =>
          Effect.gen(function* () {
            // children first, so foreign keys stay satisfied
            yield* sql`DELETE FROM expenses`;
            yield* sql`DELETE FROM envelopes`;
            yield* sql`DELETE FROM recurring_rules`;
            yield* sql`DELETE FROM periods`;
            yield* sql`DELETE FROM categories`;
            // parents first
            yield* insertCategories(snapshot.categories);
            yield* insertPeriods(snapshot.periods);
            yield* insertRecurringRules(snapshot.recurringRules);
            yield* insertEnvelopes(snapshot.envelopes);
            yield* insertExpenses(snapshot.expenses);
          }).pipe(Effect.withSpan("TransferRepository.replaceAll")),
      });
    }),
  );
}
