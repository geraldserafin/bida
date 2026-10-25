import {
  type CategoryId,
  CurrentSpace,
  Envelope,
  type EnvelopeId,
  Period,
  type PeriodId,
} from "@bida/api-contract";
import { Context, Effect, Layer, type Option, Schema } from "effect";
import { SqlClient, SqlSchema } from "effect/sql";
import type { InSpace } from "../../platform/space.ts";

/** The envelope is referenced by other rows (e.g. expenses) and cannot go. */
export class EnvelopeInUse extends Schema.TaggedError<EnvelopeInUse>()(
  "EnvelopeInUse",
  { id: Schema.String },
) {}

/** SQL only: no business rules, infrastructure failures are defects. */
export class BudgetsRepository extends Context.Service<
  BudgetsRepository,
  {
    listPeriods: InSpace<ReadonlyArray<Period>>;
    /** The period with the latest start date. */
    latestPeriod: InSpace<Option.Option<Period>>;
    findPeriod(id: PeriodId): InSpace<Option.Option<Period>>;
    insertPeriod(input: typeof Period.insert.Type): InSpace<Period>;
    updatePeriod(
      id: PeriodId,
      changes: {
        readonly name: string;
        readonly startDate: string;
        readonly endDate: string;
      },
    ): InSpace<Option.Option<Period>>;
    setIncome(
      id: PeriodId,
      incomeMinor: number,
    ): InSpace<Option.Option<Period>>;
    /** Returns false when there was nothing to delete. */
    deletePeriod(id: PeriodId): InSpace<boolean>;

    listEnvelopes(periodId: PeriodId): InSpace<ReadonlyArray<Envelope>>;
    findEnvelopeById(id: EnvelopeId): InSpace<Option.Option<Envelope>>;
    findEnvelope(
      periodId: PeriodId,
      categoryId: CategoryId,
    ): InSpace<Option.Option<Envelope>>;
    insertEnvelope(input: typeof Envelope.insert.Type): InSpace<Envelope>;
    setPlanned(
      id: EnvelopeId,
      plannedMinor: number,
    ): InSpace<Option.Option<Envelope>>;
    removeEnvelope(id: EnvelopeId): InSpace<void, EnvelopeInUse>;
  }
>()("bida/budgets/BudgetsRepository") {
  static readonly layer = Layer.effect(
    BudgetsRepository,
    Effect.gen(function* () {
      const sql = yield* SqlClient.SqlClient;

      // `date` columns are read as text so they stay calendar dates and bigint
      // amounts are cast, because pg hands bigint back as a string
      const periodColumns = sql`id, name, start_date::text AS start_date,
        end_date::text AS end_date, income_minor::float8 AS income_minor, currency,
        created_at, updated_at`;
      const envelopeColumns = sql`id, period_id, category_id,
        planned_minor::float8 AS planned_minor,
        created_at, updated_at`;

      // every query runs in the space of the current request
      const inSpace = <A, E>(run: (spaceId: string) => Effect.Effect<A, E>) =>
        Effect.flatMap(CurrentSpace, (space) => run(space.id));

      const listPeriods = SqlSchema.findAll({
        Request: Schema.Void,
        Result: Period,
        execute: () =>
          inSpace(
            (spaceId) =>
              sql`SELECT ${periodColumns} FROM periods WHERE space_id = ${spaceId}
                ORDER BY start_date DESC, created_at DESC`,
          ),
      });
      const latestPeriod = SqlSchema.findOneOption({
        Request: Schema.Void,
        Result: Period,
        execute: () =>
          inSpace(
            (spaceId) =>
              sql`SELECT ${periodColumns} FROM periods WHERE space_id = ${spaceId}
                ORDER BY start_date DESC, created_at DESC LIMIT 1`,
          ),
      });
      const findPeriod = SqlSchema.findOneOption({
        Request: Schema.String,
        Result: Period,
        execute: (id) =>
          inSpace(
            (spaceId) =>
              sql`SELECT ${periodColumns} FROM periods
                WHERE id = ${id} AND space_id = ${spaceId}`,
          ),
      });
      const insertPeriod = SqlSchema.findOne({
        Request: Period.insert,
        Result: Period,
        execute: (request) =>
          inSpace(
            (spaceId) =>
              sql`INSERT INTO periods ${sql.insert({ ...request, spaceId })}
                RETURNING ${periodColumns}`,
          ),
      });
      const updateIncome = SqlSchema.findOneOption({
        Request: Schema.Struct({ id: Schema.String, incomeMinor: Schema.Int }),
        Result: Period,
        execute: ({ id, incomeMinor }) =>
          inSpace(
            (spaceId) =>
              sql`UPDATE periods SET income_minor = ${incomeMinor}, updated_at = now()
                WHERE id = ${id} AND space_id = ${spaceId} RETURNING ${periodColumns}`,
          ),
      });
      const updatePeriodRow = SqlSchema.findOneOption({
        Request: Schema.Struct({
          id: Schema.String,
          name: Schema.String,
          startDate: Schema.String,
          endDate: Schema.String,
        }),
        Result: Period,
        execute: ({ id, name, startDate, endDate }) =>
          inSpace(
            (spaceId) =>
              sql`UPDATE periods SET name = ${name}, start_date = ${startDate},
                end_date = ${endDate}, updated_at = now()
                WHERE id = ${id} AND space_id = ${spaceId} RETURNING ${periodColumns}`,
          ),
      });
      const deletePeriod = SqlSchema.findAll({
        Request: Schema.String,
        Result: Schema.Struct({ id: Schema.String }),
        execute: (id) =>
          inSpace(
            (spaceId) =>
              sql`DELETE FROM periods WHERE id = ${id} AND space_id = ${spaceId}
                RETURNING id`,
          ),
      });

      const listEnvelopes = SqlSchema.findAll({
        Request: Schema.String,
        Result: Envelope,
        execute: (periodId) =>
          inSpace(
            (spaceId) =>
              sql`SELECT ${envelopeColumns} FROM envelopes
                WHERE period_id = ${periodId} AND space_id = ${spaceId}
                ORDER BY created_at, id`,
          ),
      });
      const findEnvelopeById = SqlSchema.findOneOption({
        Request: Schema.String,
        Result: Envelope,
        execute: (id) =>
          inSpace(
            (spaceId) =>
              sql`SELECT ${envelopeColumns} FROM envelopes
                WHERE id = ${id} AND space_id = ${spaceId}`,
          ),
      });
      const findEnvelope = SqlSchema.findOneOption({
        Request: Schema.Struct({
          periodId: Schema.String,
          categoryId: Schema.String,
        }),
        Result: Envelope,
        execute: ({ periodId, categoryId }) =>
          inSpace(
            (spaceId) =>
              sql`SELECT ${envelopeColumns} FROM envelopes
                WHERE period_id = ${periodId} AND category_id = ${categoryId}
                  AND space_id = ${spaceId}`,
          ),
      });
      const insertEnvelope = SqlSchema.findOne({
        Request: Envelope.insert,
        Result: Envelope,
        execute: (request) =>
          inSpace(
            (spaceId) =>
              sql`INSERT INTO envelopes ${sql.insert({ ...request, spaceId })}
                RETURNING ${envelopeColumns}`,
          ),
      });
      const updatePlanned = SqlSchema.findOneOption({
        Request: Schema.Struct({ id: Schema.String, plannedMinor: Schema.Int }),
        Result: Envelope,
        execute: ({ id, plannedMinor }) =>
          inSpace(
            (spaceId) =>
              sql`UPDATE envelopes SET planned_minor = ${plannedMinor}, updated_at = now()
                WHERE id = ${id} AND space_id = ${spaceId} RETURNING ${envelopeColumns}`,
          ),
      });
      const deleteEnvelope = SqlSchema.void({
        Request: Schema.String,
        execute: (id) =>
          inSpace(
            (spaceId) =>
              sql`DELETE FROM envelopes WHERE id = ${id} AND space_id = ${spaceId}`,
          ),
      });

      return BudgetsRepository.of({
        listPeriods: listPeriods().pipe(
          Effect.orDie,
          Effect.withSpan("BudgetsRepository.listPeriods"),
        ),
        latestPeriod: latestPeriod().pipe(
          Effect.orDie,
          Effect.withSpan("BudgetsRepository.latestPeriod"),
        ),
        findPeriod: (id) => findPeriod(id).pipe(Effect.orDie),
        insertPeriod: (input) => insertPeriod(input).pipe(Effect.orDie),
        updatePeriod: (id, changes) =>
          updatePeriodRow({ id, ...changes }).pipe(Effect.orDie),
        setIncome: (id, incomeMinor) =>
          updateIncome({ id, incomeMinor }).pipe(Effect.orDie),
        deletePeriod: (id) =>
          deletePeriod(id).pipe(
            Effect.map((rows) => rows.length > 0),
            Effect.orDie,
          ),

        listEnvelopes: (periodId) => listEnvelopes(periodId).pipe(Effect.orDie),
        findEnvelopeById: (id) => findEnvelopeById(id).pipe(Effect.orDie),
        findEnvelope: (periodId, categoryId) =>
          findEnvelope({ periodId, categoryId }).pipe(Effect.orDie),
        insertEnvelope: (input) => insertEnvelope(input).pipe(Effect.orDie),
        setPlanned: (id, plannedMinor) =>
          updatePlanned({ id, plannedMinor }).pipe(Effect.orDie),
        removeEnvelope: (id) =>
          deleteEnvelope(id).pipe(
            Effect.catchTag("SqlError", (error) =>
              error.reason._tag === "ConstraintError"
                ? Effect.fail(new EnvelopeInUse({ id }))
                : Effect.die(error),
            ),
            Effect.catchTag("SchemaError", Effect.die),
          ),
      });
    }),
  );
}
