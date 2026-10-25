import { Schema } from "effect";
import { Model } from "effect/schema";
import { EnvelopeId, Money, PeriodId } from "../budgets/index.ts";
import { CategoryId } from "../categories/index.ts";

export const ExpenseId = Schema.String.pipe(Schema.brand("ExpenseId"));
export type ExpenseId = typeof ExpenseId.Type;

/** Amount of an expense in minor units (grosze), always positive. */
export const Cost = Schema.Int.check(Schema.isGreaterThan(0));

// Client-provided instant: a Date in the database, an ISO string in JSON.
const SpentAt = Model.Field({
  select: Schema.DateTimeUtcFromDate,
  insert: Schema.DateTimeUtcFromDate,
  update: Schema.DateTimeUtcFromDate,
  json: Schema.DateTimeUtcFromString,
  jsonCreate: Schema.DateTimeUtcFromString,
  jsonUpdate: Schema.DateTimeUtcFromString,
});

/** Money spent from an envelope. */
export class Expense extends Model.Class<Expense>("Expense")({
  id: Model.UuidV4Insert(ExpenseId),
  envelopeId: EnvelopeId,
  /** The period of the envelope, kept on the expense for fast queries. */
  periodId: PeriodId,
  amountMinor: Cost,
  spentAt: SpentAt,
  note: Schema.NullOr(Schema.String),
  createdAt: Model.DateTimeInsertFromDate,
  updatedAt: Model.DateTimeUpdateFromDate,
}) {}

export const ExpenseJson = Expense.json.annotate({ identifier: "Expense" });

export const CreateExpense = Schema.Struct({
  envelopeId: EnvelopeId,
  amountMinor: Cost,
  spentAt: Schema.DateTimeUtcFromString,
  note: Schema.NullOr(Schema.String),
}).annotate({ identifier: "CreateExpense" });
export type CreateExpense = typeof CreateExpense.Type;

/** Replaces the editable fields. The new envelope must be in the same period. */
export const UpdateExpense = Schema.Struct({
  envelopeId: EnvelopeId,
  amountMinor: Cost,
  spentAt: Schema.DateTimeUtcFromString,
  note: Schema.NullOr(Schema.String),
}).annotate({ identifier: "UpdateExpense" });
export type UpdateExpense = typeof UpdateExpense.Type;

/** Planned versus spent for one envelope. `remainingMinor` can be negative. */
export const EnvelopeProgress = Schema.Struct({
  envelopeId: EnvelopeId,
  categoryId: CategoryId,
  plannedMinor: Money,
  spentMinor: Money,
  remainingMinor: Schema.Int,
}).annotate({ identifier: "EnvelopeProgress" });

export const PeriodProgress = Schema.Struct({
  periodId: PeriodId,
  incomeMinor: Money,
  plannedMinor: Money,
  spentMinor: Money,
  /** Planned minus spent. */
  remainingMinor: Schema.Int,
  /** Income minus planned. Negative when over-allocated. */
  unallocatedMinor: Schema.Int,
  envelopes: Schema.Array(EnvelopeProgress),
}).annotate({ identifier: "PeriodProgress" });
export type PeriodProgress = typeof PeriodProgress.Type;
