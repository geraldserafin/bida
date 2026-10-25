import {
  type CategoryId,
  type Frequency,
  RecurringRule,
  type RecurringRuleId,
} from "@bida/api-contract";
import { Context, Effect, Layer, type Option, Schema } from "effect";
import { SqlClient, SqlSchema } from "effect/sql";

export interface RuleChanges {
  readonly categoryId: CategoryId;
  readonly amountMinor: number;
  readonly frequency: Frequency;
  readonly note: string | null;
  readonly active: boolean;
}

/** SQL only: no business rules, infrastructure failures are defects. */
export class RecurringRepository extends Context.Service<
  RecurringRepository,
  {
    /** Newest first. */
    list: Effect.Effect<ReadonlyArray<RecurringRule>>;
    insert(
      input: typeof RecurringRule.insert.Type,
    ): Effect.Effect<RecurringRule>;
    /** `None` when the row does not exist. */
    update(
      id: RecurringRuleId,
      changes: RuleChanges,
    ): Effect.Effect<Option.Option<RecurringRule>>;
    /** Returns false when there was nothing to delete. */
    remove(id: RecurringRuleId): Effect.Effect<boolean>;
  }
>()("bida/recurring/RecurringRepository") {
  static readonly layer = Layer.effect(
    RecurringRepository,
    Effect.gen(function* () {
      const sql = yield* SqlClient.SqlClient;

      // bigint comes back from pg as a string, so cast it
      const columns = sql`id, category_id, amount_minor::float8 AS amount_minor,
        frequency, note, active, created_at, updated_at`;

      const list = SqlSchema.findAll({
        Request: Schema.Void,
        Result: RecurringRule,
        execute: () =>
          sql`SELECT ${columns} FROM recurring_rules
            ORDER BY created_at DESC, id DESC`,
      });
      const insert = SqlSchema.findOne({
        Request: RecurringRule.insert,
        Result: RecurringRule,
        execute: (request) =>
          sql`INSERT INTO recurring_rules ${sql.insert(request)} RETURNING ${columns}`,
      });
      const update = SqlSchema.findOneOption({
        Request: Schema.Struct({
          id: Schema.String,
          categoryId: Schema.String,
          amountMinor: Schema.Int,
          frequency: Schema.String,
          note: Schema.NullOr(Schema.String),
          active: Schema.Boolean,
        }),
        Result: RecurringRule,
        execute: ({ id, categoryId, amountMinor, frequency, note, active }) =>
          sql`UPDATE recurring_rules SET category_id = ${categoryId},
            amount_minor = ${amountMinor}, frequency = ${frequency},
            note = ${note}, active = ${active}, updated_at = now()
            WHERE id = ${id} RETURNING ${columns}`,
      });
      const remove = SqlSchema.findAll({
        Request: Schema.String,
        Result: Schema.Struct({ id: Schema.String }),
        execute: (id) =>
          sql`DELETE FROM recurring_rules WHERE id = ${id} RETURNING id`,
      });

      return RecurringRepository.of({
        list: list().pipe(
          Effect.orDie,
          Effect.withSpan("RecurringRepository.list"),
        ),
        insert: (input) => insert(input).pipe(Effect.orDie),
        update: (id, changes) => update({ id, ...changes }).pipe(Effect.orDie),
        remove: (id) =>
          remove(id).pipe(
            Effect.map((rows) => rows.length > 0),
            Effect.orDie,
          ),
      });
    }),
  );
}
