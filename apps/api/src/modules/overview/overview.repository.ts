import { Context, Effect, Layer, Schema } from "effect";
import { SqlClient, SqlSchema } from "effect/sql";

/** What happened to one envelope, split at the first day of the stretch. */
export interface EnvelopeSums {
  readonly id: string;
  readonly parentId: string | null;
  readonly allocatedBefore: number;
  readonly allocatedInside: number;
  readonly spentBefore: number;
  readonly spentInside: number;
}

export interface UserSums {
  readonly incomeInside: number;
  readonly allocatedInside: number;
  readonly spentInside: number;
  /** Income minus what was put into top-level envelopes, up to the last day. */
  readonly pool: number;
}

export interface MonthSums {
  readonly monthStart: string;
  readonly monthEnd: string;
  readonly income: number;
  readonly allocated: number;
  readonly spent: number;
}

const EnvelopeSums = Schema.Struct({
  id: Schema.String,
  parentId: Schema.NullOr(Schema.String),
  allocatedBefore: Schema.Number,
  allocatedInside: Schema.Number,
  spentBefore: Schema.Number,
  spentInside: Schema.Number,
});

const UserSums = Schema.Struct({
  incomeInside: Schema.Number,
  allocatedInside: Schema.Number,
  spentInside: Schema.Number,
  pool: Schema.Number,
});

const MonthSums = Schema.Struct({
  monthStart: Schema.String,
  monthEnd: Schema.String,
  income: Schema.Number,
  allocated: Schema.Number,
  spent: Schema.Number,
});

/**
 * Read model over everything: totals per envelope and per user. SQL only, no
 * rules. It reads the tables of other modules on purpose, because a total is
 * a question about all of them at once.
 */
export class OverviewRepository extends Context.Service<
  OverviewRepository,
  {
    /** For every envelope the user can see, up to and including `to`. */
    envelopeSums(
      userId: string,
      range: { readonly from: string; readonly to: string },
      timeZone: string,
    ): Effect.Effect<ReadonlyArray<EnvelopeSums>>;
    userSums(
      userId: string,
      range: { readonly from: string; readonly to: string },
      timeZone: string,
    ): Effect.Effect<UserSums>;
    /** Months with something in them, newest first. */
    months(
      userId: string,
      startDay: number,
      timeZone: string,
    ): Effect.Effect<ReadonlyArray<MonthSums>>;
  }
>()("bida/overview/OverviewRepository") {
  static readonly layer = Layer.effect(
    OverviewRepository,
    Effect.gen(function* () {
      const sql = yield* SqlClient.SqlClient;

      const envelopeSums = SqlSchema.findAll({
        Request: Schema.Struct({
          userId: Schema.String,
          from: Schema.String,
          to: Schema.String,
          timeZone: Schema.String,
        }),
        Result: EnvelopeSums,
        execute: ({ userId, from, to, timeZone }) =>
          sql`WITH visible AS (
              SELECT e.id, e.parent_id FROM envelopes e
              JOIN envelope_members m
                ON m.envelope_id = COALESCE(e.parent_id, e.id) AND m.user_id = ${userId}
            ), allocated AS (
              SELECT a.envelope_id,
                COALESCE(SUM(a.amount_minor) FILTER (WHERE a.made_on < ${from}::date), 0)::float8 AS before,
                COALESCE(SUM(a.amount_minor) FILTER (WHERE a.made_on >= ${from}::date), 0)::float8 AS inside
              FROM allocations a
              WHERE a.made_on <= ${to}::date
                AND a.envelope_id IN (SELECT id FROM visible)
              GROUP BY a.envelope_id
            ), spent AS (
              SELECT d.envelope_id,
                COALESCE(SUM(d.amount_minor) FILTER (WHERE d.day < ${from}::date), 0)::float8 AS before,
                COALESCE(SUM(d.amount_minor) FILTER (WHERE d.day >= ${from}::date), 0)::float8 AS inside
              FROM (
                SELECT x.envelope_id, x.amount_minor,
                  (x.spent_at AT TIME ZONE ${timeZone})::date AS day
                FROM expenses x
                WHERE x.envelope_id IN (SELECT id FROM visible)
              ) d
              WHERE d.day <= ${to}::date
              GROUP BY d.envelope_id
            )
            SELECT v.id, v.parent_id,
              COALESCE(allocated.before, 0)::float8 AS allocated_before,
              COALESCE(allocated.inside, 0)::float8 AS allocated_inside,
              COALESCE(spent.before, 0)::float8 AS spent_before,
              COALESCE(spent.inside, 0)::float8 AS spent_inside
            FROM visible v
            LEFT JOIN allocated ON allocated.envelope_id = v.id
            LEFT JOIN spent ON spent.envelope_id = v.id`,
      });

      const userSums = SqlSchema.findOne({
        Request: Schema.Struct({
          userId: Schema.String,
          from: Schema.String,
          to: Schema.String,
          timeZone: Schema.String,
        }),
        Result: UserSums,
        execute: ({ userId, from, to, timeZone }) =>
          sql`SELECT
              (SELECT COALESCE(SUM(amount_minor), 0)::float8 FROM incomes
                WHERE user_id = ${userId} AND received_on BETWEEN ${from}::date AND ${to}::date
              ) AS income_inside,
              (SELECT COALESCE(SUM(a.amount_minor), 0)::float8 FROM allocations a
                JOIN envelopes e ON e.id = a.envelope_id
                WHERE a.user_id = ${userId} AND e.parent_id IS NULL
                  AND a.made_on BETWEEN ${from}::date AND ${to}::date
              ) AS allocated_inside,
              (SELECT COALESCE(SUM(amount_minor), 0)::float8 FROM expenses
                WHERE created_by = ${userId}
                  AND (spent_at AT TIME ZONE ${timeZone})::date BETWEEN ${from}::date AND ${to}::date
              ) AS spent_inside,
              (SELECT COALESCE(SUM(amount_minor), 0)::float8 FROM incomes
                WHERE user_id = ${userId} AND received_on <= ${to}::date
              ) - (SELECT COALESCE(SUM(a.amount_minor), 0)::float8 FROM allocations a
                JOIN envelopes e ON e.id = a.envelope_id
                WHERE a.user_id = ${userId} AND e.parent_id IS NULL
                  AND a.made_on <= ${to}::date
              ) AS pool`,
      });

      const months = SqlSchema.findAll({
        Request: Schema.Struct({
          userId: Schema.String,
          startDay: Schema.Int,
          timeZone: Schema.String,
        }),
        Result: MonthSums,
        execute: ({ userId, startDay, timeZone }) =>
          sql`WITH events AS (
              SELECT received_on AS day, amount_minor AS income,
                0::bigint AS allocated, 0::bigint AS spent
              FROM incomes WHERE user_id = ${userId}
              UNION ALL
              SELECT a.made_on, 0, a.amount_minor, 0
              FROM allocations a JOIN envelopes e ON e.id = a.envelope_id
              WHERE a.user_id = ${userId} AND e.parent_id IS NULL
              UNION ALL
              SELECT (spent_at AT TIME ZONE ${timeZone})::date, 0, 0, amount_minor
              FROM expenses WHERE created_by = ${userId}
            ), bucketed AS (
              SELECT (date_trunc('month', day - make_interval(days => ${startDay} - 1))
                  + make_interval(days => ${startDay} - 1))::date AS month_start,
                income, allocated, spent
              FROM events
            )
            SELECT month_start::text AS month_start,
              (month_start + interval '1 month' - interval '1 day')::date::text AS month_end,
              SUM(income)::float8 AS income,
              SUM(allocated)::float8 AS allocated,
              SUM(spent)::float8 AS spent
            FROM bucketed GROUP BY month_start ORDER BY month_start DESC`,
      });

      return OverviewRepository.of({
        envelopeSums: (userId, range, timeZone) =>
          envelopeSums({ userId, ...range, timeZone }).pipe(Effect.orDie),
        userSums: (userId, range, timeZone) =>
          userSums({ userId, ...range, timeZone }).pipe(Effect.orDie),
        months: (userId, startDay, timeZone) =>
          months({ userId, startDay, timeZone }).pipe(Effect.orDie),
      });
    }),
  );
}
