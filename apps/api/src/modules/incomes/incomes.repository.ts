import { Income, type IncomeId } from "@bida/api-contract";
import { Context, Effect, Layer, type Option, Schema } from "effect";
import { SqlClient, SqlSchema } from "effect/sql";

export interface IncomeChanges {
  readonly amountMinor: number;
  readonly receivedOn: string;
  readonly note: string | null;
}

/** SQL only: no business rules, infrastructure failures are defects. */
export class IncomesRepository extends Context.Service<
  IncomesRepository,
  {
    /** Newest first; both days are included. */
    list(
      userId: string,
      range: {
        readonly from?: string | undefined;
        readonly to?: string | undefined;
      },
    ): Effect.Effect<ReadonlyArray<Income>>;
    /**
     * `link` says which recurring income made it and for which stretch (its
     * first day); the database allows a rule once per stretch.
     */
    insert(
      input: typeof Income.insert.Type,
      link?: { readonly ruleId: string; readonly month: string },
    ): Effect.Effect<Income>;
    /** Of the rules, those that already made an income for the stretch. */
    appliedRuleIds(
      ruleIds: ReadonlyArray<string>,
      month: string,
    ): Effect.Effect<ReadonlySet<string>>;
    /** `None` when the user has no such income. */
    update(
      userId: string,
      id: IncomeId,
      changes: IncomeChanges,
    ): Effect.Effect<Option.Option<Income>>;
    /** Returns false when there was nothing to delete. */
    remove(userId: string, id: IncomeId): Effect.Effect<boolean>;
  }
>()("bida/incomes/IncomesRepository") {
  static readonly layer = Layer.effect(
    IncomesRepository,
    Effect.gen(function* () {
      const sql = yield* SqlClient.SqlClient;

      // bigint comes back from pg as a string and `date` as a Date: cast both
      const columns = sql`id, user_id, amount_minor::float8 AS amount_minor,
        received_on::text AS received_on, note, created_at, updated_at`;

      const list = SqlSchema.findAll({
        Request: Schema.Struct({
          userId: Schema.String,
          from: Schema.optional(Schema.String),
          to: Schema.optional(Schema.String),
        }),
        Result: Income,
        execute: ({ userId, from, to }) => {
          const conditions = [sql`user_id = ${userId}`];
          if (from !== undefined) conditions.push(sql`received_on >= ${from}`);
          if (to !== undefined) conditions.push(sql`received_on <= ${to}`);
          return sql`SELECT ${columns} FROM incomes WHERE ${sql.and(conditions)}
            ORDER BY received_on DESC, created_at DESC, id DESC`;
        },
      });
      const insert = SqlSchema.findOne({
        Request: Schema.Struct({
          row: Income.insert,
          ruleId: Schema.NullOr(Schema.String),
          month: Schema.NullOr(Schema.String),
        }),
        Result: Income,
        execute: ({ row, ruleId, month }) =>
          sql`INSERT INTO incomes ${sql.insert({
            ...row,
            recurringId: ruleId,
            recurringMonth: month,
          })} RETURNING ${columns}`,
      });
      const applied = SqlSchema.findAll({
        Request: Schema.Struct({
          ruleIds: Schema.Array(Schema.String),
          month: Schema.String,
        }),
        Result: Schema.Struct({ recurringId: Schema.String }),
        execute: ({ ruleIds, month }) =>
          ruleIds.length === 0
            ? sql`SELECT NULL::uuid AS recurring_id WHERE FALSE`
            : sql`SELECT recurring_id FROM incomes
              WHERE ${sql.in("recurring_id", ruleIds)}
                AND recurring_month = ${month}`,
      });
      const update = SqlSchema.findOneOption({
        Request: Schema.Struct({
          userId: Schema.String,
          id: Schema.String,
          amountMinor: Schema.Int,
          receivedOn: Schema.String,
          note: Schema.NullOr(Schema.String),
        }),
        Result: Income,
        execute: ({ userId, id, amountMinor, receivedOn, note }) =>
          sql`UPDATE incomes SET amount_minor = ${amountMinor},
            received_on = ${receivedOn}, note = ${note}, updated_at = now()
            WHERE id = ${id} AND user_id = ${userId} RETURNING ${columns}`,
      });
      const remove = SqlSchema.findAll({
        Request: Schema.Struct({ userId: Schema.String, id: Schema.String }),
        Result: Schema.Struct({ id: Schema.String }),
        execute: ({ userId, id }) =>
          sql`DELETE FROM incomes WHERE id = ${id} AND user_id = ${userId}
            RETURNING id`,
      });

      return IncomesRepository.of({
        list: (userId, range) => list({ userId, ...range }).pipe(Effect.orDie),
        insert: (row, link) =>
          insert({
            row,
            ruleId: link?.ruleId ?? null,
            month: link?.month ?? null,
          }).pipe(Effect.orDie),
        appliedRuleIds: (ruleIds, month) =>
          applied({ ruleIds, month }).pipe(
            Effect.map((rows) => new Set(rows.map((row) => row.recurringId))),
            Effect.orDie,
          ),
        update: (userId, id, changes) =>
          update({ userId, id, ...changes }).pipe(Effect.orDie),
        remove: (userId, id) =>
          remove({ userId, id }).pipe(
            Effect.map((rows) => rows.length > 0),
            Effect.orDie,
          ),
      });
    }),
  );
}
