import {
  AllocationRule,
  type AllocationRuleId,
  type EnvelopeId,
  RecurringIncome,
  type RecurringIncomeId,
} from "@bida/api-contract";
import { Context, Effect, Layer, type Option, Schema } from "effect";
import { SqlClient, SqlSchema } from "effect/sql";

export interface IncomeRuleChanges {
  readonly amountMinor: number;
  readonly dayOfMonth: number;
  readonly note: string | null;
  readonly active: boolean;
}

export interface AllocationRuleChanges extends IncomeRuleChanges {
  readonly envelopeId: EnvelopeId;
}

/** SQL only: the rules that bring a recurring income into the app. */
export class RecurringIncomesRepository extends Context.Service<
  RecurringIncomesRepository,
  {
    /** The user's own rules, newest first. */
    list(userId: string): Effect.Effect<ReadonlyArray<RecurringIncome>>;
    insert(
      input: typeof RecurringIncome.insert.Type,
    ): Effect.Effect<RecurringIncome>;
    /** `None` when the user has no such rule. */
    update(
      userId: string,
      id: RecurringIncomeId,
      changes: IncomeRuleChanges,
    ): Effect.Effect<Option.Option<RecurringIncome>>;
    /** Returns false when there was nothing to delete. */
    remove(userId: string, id: RecurringIncomeId): Effect.Effect<boolean>;
  }
>()("bida/recurring/RecurringIncomesRepository") {
  static readonly layer = Layer.effect(
    RecurringIncomesRepository,
    Effect.gen(function* () {
      const sql = yield* SqlClient.SqlClient;

      // bigint comes back from pg as a string, so cast it
      const columns = sql`id, user_id, amount_minor::float8 AS amount_minor,
        day_of_month, note, active, created_at, updated_at`;

      const list = SqlSchema.findAll({
        Request: Schema.String,
        Result: RecurringIncome,
        execute: (userId) =>
          sql`SELECT ${columns} FROM recurring_incomes WHERE user_id = ${userId}
            ORDER BY created_at DESC, id DESC`,
      });
      const insert = SqlSchema.findOne({
        Request: RecurringIncome.insert,
        Result: RecurringIncome,
        execute: (request) =>
          sql`INSERT INTO recurring_incomes ${sql.insert(request)}
            RETURNING ${columns}`,
      });
      const update = SqlSchema.findOneOption({
        Request: Schema.Struct({
          userId: Schema.String,
          id: Schema.String,
          amountMinor: Schema.Int,
          dayOfMonth: Schema.Int,
          note: Schema.NullOr(Schema.String),
          active: Schema.Boolean,
        }),
        Result: RecurringIncome,
        execute: ({ userId, id, amountMinor, dayOfMonth, note, active }) =>
          sql`UPDATE recurring_incomes SET amount_minor = ${amountMinor},
            day_of_month = ${dayOfMonth}, note = ${note}, active = ${active},
            updated_at = now()
            WHERE id = ${id} AND user_id = ${userId} RETURNING ${columns}`,
      });
      const remove = SqlSchema.findAll({
        Request: Schema.Struct({ userId: Schema.String, id: Schema.String }),
        Result: Schema.Struct({ id: Schema.String }),
        execute: ({ userId, id }) =>
          sql`DELETE FROM recurring_incomes
            WHERE id = ${id} AND user_id = ${userId} RETURNING id`,
      });

      return RecurringIncomesRepository.of({
        list: (userId) => list(userId).pipe(Effect.orDie),
        insert: (input) => insert(input).pipe(Effect.orDie),
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

/** SQL only: the rules that put a sum into an envelope every month. */
export class AllocationRulesRepository extends Context.Service<
  AllocationRulesRepository,
  {
    /** The user's own rules, newest first. */
    list(userId: string): Effect.Effect<ReadonlyArray<AllocationRule>>;
    insert(
      input: typeof AllocationRule.insert.Type,
    ): Effect.Effect<AllocationRule>;
    /** `None` when the user has no such rule. */
    update(
      userId: string,
      id: AllocationRuleId,
      changes: AllocationRuleChanges,
    ): Effect.Effect<Option.Option<AllocationRule>>;
    /** Returns false when there was nothing to delete. */
    remove(userId: string, id: AllocationRuleId): Effect.Effect<boolean>;
  }
>()("bida/recurring/AllocationRulesRepository") {
  static readonly layer = Layer.effect(
    AllocationRulesRepository,
    Effect.gen(function* () {
      const sql = yield* SqlClient.SqlClient;

      const columns = sql`id, user_id, envelope_id, amount_minor::float8 AS amount_minor,
        day_of_month, note, active, created_at, updated_at`;

      const list = SqlSchema.findAll({
        Request: Schema.String,
        Result: AllocationRule,
        execute: (userId) =>
          sql`SELECT ${columns} FROM allocation_rules WHERE user_id = ${userId}
            ORDER BY created_at DESC, id DESC`,
      });
      const insert = SqlSchema.findOne({
        Request: AllocationRule.insert,
        Result: AllocationRule,
        execute: (request) =>
          sql`INSERT INTO allocation_rules ${sql.insert(request)}
            RETURNING ${columns}`,
      });
      const update = SqlSchema.findOneOption({
        Request: Schema.Struct({
          userId: Schema.String,
          id: Schema.String,
          envelopeId: Schema.String,
          amountMinor: Schema.Int,
          dayOfMonth: Schema.Int,
          note: Schema.NullOr(Schema.String),
          active: Schema.Boolean,
        }),
        Result: AllocationRule,
        execute: ({
          userId,
          id,
          envelopeId,
          amountMinor,
          dayOfMonth,
          note,
          active,
        }) =>
          sql`UPDATE allocation_rules SET envelope_id = ${envelopeId},
            amount_minor = ${amountMinor}, day_of_month = ${dayOfMonth},
            note = ${note}, active = ${active}, updated_at = now()
            WHERE id = ${id} AND user_id = ${userId} RETURNING ${columns}`,
      });
      const remove = SqlSchema.findAll({
        Request: Schema.Struct({ userId: Schema.String, id: Schema.String }),
        Result: Schema.Struct({ id: Schema.String }),
        execute: ({ userId, id }) =>
          sql`DELETE FROM allocation_rules
            WHERE id = ${id} AND user_id = ${userId} RETURNING id`,
      });

      return AllocationRulesRepository.of({
        list: (userId) => list(userId).pipe(Effect.orDie),
        insert: (input) => insert(input).pipe(Effect.orDie),
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
