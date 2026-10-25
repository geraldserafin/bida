import { Contribution, CurrentSpace, type PeriodId } from "@bida/api-contract";
import { Context, Effect, Layer, type Option, Schema } from "effect";
import { SqlClient, SqlSchema } from "effect/sql";
import type { InSpace } from "../../platform/space.ts";

/** SQL only, scoped to the space of the current request. */
export class ContributionsRepository extends Context.Service<
  ContributionsRepository,
  {
    /** Newest first. */
    listForPeriod(periodId: PeriodId): InSpace<ReadonlyArray<Contribution>>;
    findById(id: string): InSpace<Option.Option<Contribution>>;
    insert(input: typeof Contribution.insert.Type): InSpace<Contribution>;
    /** Returns false when there was nothing to delete. */
    delete(id: string): InSpace<boolean>;
    /** Total paid in per period; periods without contributions are absent. */
    totalByPeriod: InSpace<ReadonlyMap<PeriodId, number>>;
  }
>()("bida/contributions/ContributionsRepository") {
  static readonly layer = Layer.effect(
    ContributionsRepository,
    Effect.gen(function* () {
      const sql = yield* SqlClient.SqlClient;
      // bigint comes back from pg as a string, so cast it
      const columns = sql`id, period_id, user_id, amount_minor::float8 AS amount_minor,
        contributed_at, note, created_at`;
      const inSpace = <A, E>(run: (spaceId: string) => Effect.Effect<A, E>) =>
        Effect.flatMap(CurrentSpace, (space) => run(space.id));

      const listForPeriod = SqlSchema.findAll({
        Request: Schema.String,
        Result: Contribution,
        execute: (periodId) =>
          inSpace(
            (spaceId) =>
              sql`SELECT ${columns} FROM contributions
                WHERE period_id = ${periodId} AND space_id = ${spaceId}
                ORDER BY contributed_at DESC, id`,
          ),
      });
      const findById = SqlSchema.findOneOption({
        Request: Schema.String,
        Result: Contribution,
        execute: (id) =>
          inSpace(
            (spaceId) =>
              sql`SELECT ${columns} FROM contributions
                WHERE id = ${id} AND space_id = ${spaceId}`,
          ),
      });
      const insert = SqlSchema.findOne({
        Request: Contribution.insert,
        Result: Contribution,
        execute: (request) =>
          inSpace(
            (spaceId) =>
              sql`INSERT INTO contributions ${sql.insert({ ...request, spaceId })}
                RETURNING ${columns}`,
          ),
      });
      const remove = SqlSchema.findAll({
        Request: Schema.String,
        Result: Schema.Struct({ id: Schema.String }),
        execute: (id) =>
          inSpace(
            (spaceId) =>
              sql`DELETE FROM contributions WHERE id = ${id} AND space_id = ${spaceId}
                RETURNING id`,
          ),
      });
      const totalByPeriod = SqlSchema.findAll({
        Request: Schema.Void,
        Result: Schema.Struct({
          periodId: Schema.String,
          totalMinor: Schema.Number,
        }),
        execute: () =>
          inSpace(
            (spaceId) =>
              sql`SELECT period_id, SUM(amount_minor)::float8 AS total_minor
                FROM contributions WHERE space_id = ${spaceId} GROUP BY period_id`,
          ),
      });

      return ContributionsRepository.of({
        listForPeriod: (periodId) => listForPeriod(periodId).pipe(Effect.orDie),
        findById: (id) => findById(id).pipe(Effect.orDie),
        insert: (input) => insert(input).pipe(Effect.orDie),
        delete: (id) =>
          remove(id).pipe(
            Effect.map((rows) => rows.length > 0),
            Effect.orDie,
          ),
        totalByPeriod: totalByPeriod().pipe(
          Effect.map(
            (rows) =>
              new Map(
                rows.map((row) => [row.periodId as PeriodId, row.totalMinor]),
              ),
          ),
          Effect.orDie,
        ),
      });
    }),
  );
}
