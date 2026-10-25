import {
  type CategoryId,
  type Currency,
  CurrentSpace,
  type Frequency,
  RecurringRule,
  type RecurringRuleId,
} from "@bida/api-contract";
import { Context, Effect, Layer, type Option, Schema } from "effect";
import { SqlClient, SqlSchema } from "effect/sql";
import type { InSpace } from "../../platform/space.ts";

export interface RuleChanges {
  readonly categoryId: CategoryId;
  readonly amountMinor: number;
  readonly currency: Currency;
  readonly frequency: Frequency;
  readonly note: string | null;
  readonly active: boolean;
}

/** SQL only: no business rules, infrastructure failures are defects. */
export class RecurringRepository extends Context.Service<
  RecurringRepository,
  {
    /** Newest first. */
    list: InSpace<ReadonlyArray<RecurringRule>>;
    insert(input: typeof RecurringRule.insert.Type): InSpace<RecurringRule>;
    /** `None` when the row does not exist. */
    update(
      id: RecurringRuleId,
      changes: RuleChanges,
    ): InSpace<Option.Option<RecurringRule>>;
    /** Returns false when there was nothing to delete. */
    remove(id: RecurringRuleId): InSpace<boolean>;
  }
>()("bida/recurring/RecurringRepository") {
  static readonly layer = Layer.effect(
    RecurringRepository,
    Effect.gen(function* () {
      const sql = yield* SqlClient.SqlClient;

      // bigint comes back from pg as a string, so cast it
      const columns = sql`id, category_id, amount_minor::float8 AS amount_minor, currency,
        frequency, note, active, created_at, updated_at`;

      // every query runs in the space of the current request
      const inSpace = <A, E>(run: (spaceId: string) => Effect.Effect<A, E>) =>
        Effect.flatMap(CurrentSpace, (space) => run(space.id));

      const list = SqlSchema.findAll({
        Request: Schema.Void,
        Result: RecurringRule,
        execute: () =>
          inSpace(
            (spaceId) =>
              sql`SELECT ${columns} FROM recurring_rules WHERE space_id = ${spaceId}
                ORDER BY created_at DESC, id DESC`,
          ),
      });
      const insert = SqlSchema.findOne({
        Request: RecurringRule.insert,
        Result: RecurringRule,
        execute: (request) =>
          inSpace(
            (spaceId) =>
              sql`INSERT INTO recurring_rules ${sql.insert({ ...request, spaceId })}
                RETURNING ${columns}`,
          ),
      });
      const update = SqlSchema.findOneOption({
        Request: Schema.Struct({
          id: Schema.String,
          categoryId: Schema.String,
          amountMinor: Schema.Int,
          currency: Schema.String,
          frequency: Schema.String,
          note: Schema.NullOr(Schema.String),
          active: Schema.Boolean,
        }),
        Result: RecurringRule,
        execute: ({
          id,
          categoryId,
          amountMinor,
          currency,
          frequency,
          note,
          active,
        }) =>
          inSpace(
            (spaceId) =>
              sql`UPDATE recurring_rules SET category_id = ${categoryId},
                amount_minor = ${amountMinor}, currency = ${currency},
                frequency = ${frequency}, note = ${note}, active = ${active},
                updated_at = now()
                WHERE id = ${id} AND space_id = ${spaceId} RETURNING ${columns}`,
          ),
      });
      const remove = SqlSchema.findAll({
        Request: Schema.String,
        Result: Schema.Struct({ id: Schema.String }),
        execute: (id) =>
          inSpace(
            (spaceId) =>
              sql`DELETE FROM recurring_rules
                WHERE id = ${id} AND space_id = ${spaceId} RETURNING id`,
          ),
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
