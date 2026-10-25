import {
  type EnvelopeId,
  Expense,
  type ExpenseId,
  type RecurringRuleId,
} from "@bida/api-contract";
import {
  Context,
  type DateTime,
  Effect,
  Layer,
  type Option,
  Schema,
} from "effect";
import { SqlClient, SqlSchema } from "effect/sql";

export interface ExpenseFilter {
  readonly envelopeIds: ReadonlyArray<EnvelopeId>;
  readonly from?: DateTime.Utc | undefined;
  readonly to?: DateTime.Utc | undefined;
  readonly limit: number;
  readonly offset: number;
}

export interface ExpenseChanges {
  readonly envelopeId: EnvelopeId;
  readonly amountMinor: number;
  readonly spentAt: DateTime.Utc;
  readonly note: string | null;
}

/** SQL only: no business rules, infrastructure failures are defects. */
export class ExpensesRepository extends Context.Service<
  ExpensesRepository,
  {
    /**
     * `recurringMonth` is the first day of the stretch a recurring rule was
     * applied to; the database allows a rule once per such day.
     */
    insert(
      input: typeof Expense.insert.Type,
      recurringMonth: string | null,
    ): Effect.Effect<Expense>;
    findById(id: ExpenseId): Effect.Effect<Option.Option<Expense>>;
    /** `None` when the row does not exist. */
    update(
      id: ExpenseId,
      changes: ExpenseChanges,
    ): Effect.Effect<Option.Option<Expense>>;
    /** Returns false when there was nothing to delete. */
    remove(id: ExpenseId): Effect.Effect<boolean>;
    /** Newest first. */
    list(filter: ExpenseFilter): Effect.Effect<ReadonlyArray<Expense>>;
    /** Of the rules, those that already produced an expense for the stretch. */
    appliedRecurringIds(
      ruleIds: ReadonlyArray<RecurringRuleId>,
      recurringMonth: string,
    ): Effect.Effect<ReadonlySet<RecurringRuleId>>;
  }
>()("bida/expenses/ExpensesRepository") {
  static readonly layer = Layer.effect(
    ExpensesRepository,
    Effect.gen(function* () {
      const sql = yield* SqlClient.SqlClient;

      // bigint comes back from pg as a string, so cast it
      const columns = sql`id, envelope_id, created_by,
        amount_minor::float8 AS amount_minor, spent_at, note, recurring_id,
        created_at, updated_at`;

      const insert = SqlSchema.findOne({
        Request: Schema.Struct({
          row: Expense.insert,
          recurringMonth: Schema.NullOr(Schema.String),
        }),
        Result: Expense,
        execute: ({ row, recurringMonth }) =>
          sql`INSERT INTO expenses ${sql.insert({ ...row, recurringMonth })}
            RETURNING ${columns}`,
      });
      const findById = SqlSchema.findOneOption({
        Request: Schema.String,
        Result: Expense,
        execute: (id) => sql`SELECT ${columns} FROM expenses WHERE id = ${id}`,
      });
      const update = SqlSchema.findOneOption({
        Request: Schema.Struct({
          id: Schema.String,
          envelopeId: Schema.String,
          amountMinor: Schema.Int,
          spentAt: Schema.DateTimeUtcFromDate,
          note: Schema.NullOr(Schema.String),
        }),
        Result: Expense,
        execute: ({ id, envelopeId, amountMinor, spentAt, note }) =>
          sql`UPDATE expenses SET envelope_id = ${envelopeId},
            amount_minor = ${amountMinor}, spent_at = ${spentAt}, note = ${note},
            updated_at = now()
            WHERE id = ${id} RETURNING ${columns}`,
      });
      const remove = SqlSchema.findAll({
        Request: Schema.String,
        Result: Schema.Struct({ id: Schema.String }),
        execute: (id) =>
          sql`DELETE FROM expenses WHERE id = ${id} RETURNING id`,
      });
      const list = SqlSchema.findAll({
        Request: Schema.Struct({
          envelopeIds: Schema.Array(Schema.String),
          from: Schema.optional(Schema.DateTimeUtcFromDate),
          to: Schema.optional(Schema.DateTimeUtcFromDate),
          limit: Schema.Int,
          offset: Schema.Int,
        }),
        Result: Expense,
        execute: ({ envelopeIds, from, to, limit, offset }) => {
          // sql.in with an empty list would be invalid SQL
          const conditions =
            envelopeIds.length === 0
              ? [sql`FALSE`]
              : [sql`${sql.in("envelope_id", envelopeIds)}`];
          if (from !== undefined) conditions.push(sql`spent_at >= ${from}`);
          if (to !== undefined) conditions.push(sql`spent_at < ${to}`);
          return sql`SELECT ${columns} FROM expenses
            WHERE ${sql.and(conditions)}
            ORDER BY spent_at DESC, id DESC
            LIMIT ${limit} OFFSET ${offset}`;
        },
      });
      const appliedRecurringIds = SqlSchema.findAll({
        Request: Schema.Struct({
          ruleIds: Schema.Array(Schema.String),
          recurringMonth: Schema.String,
        }),
        Result: Schema.Struct({ recurringId: Schema.String }),
        execute: ({ ruleIds, recurringMonth }) =>
          ruleIds.length === 0
            ? sql`SELECT NULL::uuid AS recurring_id WHERE FALSE`
            : sql`SELECT recurring_id FROM expenses
              WHERE ${sql.in("recurring_id", ruleIds)}
                AND recurring_month = ${recurringMonth}`,
      });

      return ExpensesRepository.of({
        insert: (row, recurringMonth) =>
          insert({ row, recurringMonth }).pipe(Effect.orDie),
        findById: (id) => findById(id).pipe(Effect.orDie),
        update: (id, changes) => update({ id, ...changes }).pipe(Effect.orDie),
        remove: (id) =>
          remove(id).pipe(
            Effect.map((rows) => rows.length > 0),
            Effect.orDie,
          ),
        list: (filter) => list(filter).pipe(Effect.orDie),
        appliedRecurringIds: (ruleIds, recurringMonth) =>
          appliedRecurringIds({ ruleIds, recurringMonth }).pipe(
            Effect.map(
              (rows) =>
                new Set(rows.map((row) => row.recurringId as RecurringRuleId)),
            ),
            Effect.orDie,
          ),
      });
    }),
  );
}
