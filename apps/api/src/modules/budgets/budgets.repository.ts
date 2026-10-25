import {
  type CategoryId,
  Envelope,
  type EnvelopeId,
  Period,
  type PeriodId,
} from "@bida/api-contract";
import { Context, Effect, Layer, type Option, Schema } from "effect";
import { SqlClient, SqlSchema } from "effect/sql";

/** The envelope is referenced by other rows (e.g. expenses) and cannot go. */
export class EnvelopeInUse extends Schema.TaggedError<EnvelopeInUse>()(
  "EnvelopeInUse",
  { id: Schema.String },
) {}

/** SQL only: no business rules, infrastructure failures are defects. */
export class BudgetsRepository extends Context.Service<
  BudgetsRepository,
  {
    listPeriods: Effect.Effect<ReadonlyArray<Period>>;
    /** The period with the latest start date. */
    latestPeriod: Effect.Effect<Option.Option<Period>>;
    findPeriod(id: PeriodId): Effect.Effect<Option.Option<Period>>;
    insertPeriod(input: typeof Period.insert.Type): Effect.Effect<Period>;
    setIncome(
      id: PeriodId,
      incomeMinor: number,
    ): Effect.Effect<Option.Option<Period>>;
    /** Returns false when there was nothing to delete. */
    deletePeriod(id: PeriodId): Effect.Effect<boolean>;

    listEnvelopes(periodId: PeriodId): Effect.Effect<ReadonlyArray<Envelope>>;
    findEnvelopeById(id: EnvelopeId): Effect.Effect<Option.Option<Envelope>>;
    findEnvelope(
      periodId: PeriodId,
      categoryId: CategoryId,
    ): Effect.Effect<Option.Option<Envelope>>;
    insertEnvelope(input: typeof Envelope.insert.Type): Effect.Effect<Envelope>;
    setPlanned(
      id: EnvelopeId,
      plannedMinor: number,
    ): Effect.Effect<Option.Option<Envelope>>;
    removeEnvelope(id: EnvelopeId): Effect.Effect<void, EnvelopeInUse>;
  }
>()("bida/budgets/BudgetsRepository") {
  static readonly layer = Layer.effect(
    BudgetsRepository,
    Effect.gen(function* () {
      const sql = yield* SqlClient.SqlClient;

      // `date` columns are read as text so they stay calendar dates and bigint
      // amounts are cast, because pg hands bigint back as a string
      const periodColumns = sql`id, name, start_date::text AS start_date,
        end_date::text AS end_date, income_minor::float8 AS income_minor,
        created_at, updated_at`;
      const envelopeColumns = sql`id, period_id, category_id,
        planned_minor::float8 AS planned_minor,
        created_at, updated_at`;

      const listPeriods = SqlSchema.findAll({
        Request: Schema.Void,
        Result: Period,
        execute: () =>
          sql`SELECT ${periodColumns} FROM periods
            ORDER BY start_date DESC, created_at DESC`,
      });
      const latestPeriod = SqlSchema.findOneOption({
        Request: Schema.Void,
        Result: Period,
        execute: () =>
          sql`SELECT ${periodColumns} FROM periods
            ORDER BY start_date DESC, created_at DESC LIMIT 1`,
      });
      const findPeriod = SqlSchema.findOneOption({
        Request: Schema.String,
        Result: Period,
        execute: (id) =>
          sql`SELECT ${periodColumns} FROM periods WHERE id = ${id}`,
      });
      const insertPeriod = SqlSchema.findOne({
        Request: Period.insert,
        Result: Period,
        execute: (request) =>
          sql`INSERT INTO periods ${sql.insert(request)} RETURNING ${periodColumns}`,
      });
      const updateIncome = SqlSchema.findOneOption({
        Request: Schema.Struct({ id: Schema.String, incomeMinor: Schema.Int }),
        Result: Period,
        execute: ({ id, incomeMinor }) =>
          sql`UPDATE periods SET income_minor = ${incomeMinor}, updated_at = now()
            WHERE id = ${id} RETURNING ${periodColumns}`,
      });
      const deletePeriod = SqlSchema.findAll({
        Request: Schema.String,
        Result: Schema.Struct({ id: Schema.String }),
        execute: (id) => sql`DELETE FROM periods WHERE id = ${id} RETURNING id`,
      });

      const listEnvelopes = SqlSchema.findAll({
        Request: Schema.String,
        Result: Envelope,
        execute: (periodId) =>
          sql`SELECT ${envelopeColumns} FROM envelopes
            WHERE period_id = ${periodId} ORDER BY created_at, id`,
      });
      const findEnvelopeById = SqlSchema.findOneOption({
        Request: Schema.String,
        Result: Envelope,
        execute: (id) =>
          sql`SELECT ${envelopeColumns} FROM envelopes WHERE id = ${id}`,
      });
      const findEnvelope = SqlSchema.findOneOption({
        Request: Schema.Struct({
          periodId: Schema.String,
          categoryId: Schema.String,
        }),
        Result: Envelope,
        execute: ({ periodId, categoryId }) =>
          sql`SELECT ${envelopeColumns} FROM envelopes
            WHERE period_id = ${periodId} AND category_id = ${categoryId}`,
      });
      const insertEnvelope = SqlSchema.findOne({
        Request: Envelope.insert,
        Result: Envelope,
        execute: (request) =>
          sql`INSERT INTO envelopes ${sql.insert(request)} RETURNING ${envelopeColumns}`,
      });
      const updatePlanned = SqlSchema.findOneOption({
        Request: Schema.Struct({ id: Schema.String, plannedMinor: Schema.Int }),
        Result: Envelope,
        execute: ({ id, plannedMinor }) =>
          sql`UPDATE envelopes SET planned_minor = ${plannedMinor}, updated_at = now()
            WHERE id = ${id} RETURNING ${envelopeColumns}`,
      });
      const deleteEnvelope = SqlSchema.void({
        Request: Schema.String,
        execute: (id) => sql`DELETE FROM envelopes WHERE id = ${id}`,
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
