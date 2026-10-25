import { Schema } from "effect";
import { Model } from "effect/schema";
import { EnvelopeId, Money, PeriodId } from "../budgets/index.ts";
import { CategoryId } from "../categories/index.ts";
import { Currency } from "../currency/index.ts";
import { RecurringRuleId } from "../recurring/recurring.model.ts";

export const ExpenseId = Schema.String.pipe(Schema.brand("ExpenseId"));
export type ExpenseId = typeof ExpenseId.Type;

/** Amount of an expense in minor units, always positive. */
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
  /** In the currency of the period, this is what counts against the envelope. */
  amountMinor: Cost,
  /**
   * What was actually paid when it was in another currency than the period's.
   * Both are null for an ordinary expense.
   */
  originalAmountMinor: Schema.NullOr(Cost),
  originalCurrency: Schema.NullOr(Currency),
  spentAt: SpentAt,
  note: Schema.NullOr(Schema.String),
  /** Set when the expense was generated from a recurring rule. */
  recurringId: Schema.NullOr(RecurringRuleId),
  createdAt: Model.DateTimeInsertFromDate,
  updatedAt: Model.DateTimeUpdateFromDate,
}) {}

export const ExpenseJson = Expense.json.annotate({ identifier: "Expense" });

/** What was actually paid, when it was not in the currency of the period. */
export const OriginalAmount = Schema.Struct({
  amountMinor: Cost,
  currency: Currency,
}).annotate({ identifier: "OriginalAmount" });
export type OriginalAmount = typeof OriginalAmount.Type;

export const CreateExpense = Schema.Struct({
  envelopeId: EnvelopeId,
  /** In the currency of the period. */
  amountMinor: Cost,
  spentAt: Schema.DateTimeUtcFromString,
  note: Schema.NullOr(Schema.String),
  /** Set to record a payment in another currency. Ignored when it is the period's currency. */
  original: Schema.optional(OriginalAmount),
}).annotate({ identifier: "CreateExpense" });
export type CreateExpense = typeof CreateExpense.Type;

/** Replaces the editable fields. The new envelope must be in the same period. */
export const UpdateExpense = Schema.Struct({
  envelopeId: EnvelopeId,
  amountMinor: Cost,
  spentAt: Schema.DateTimeUtcFromString,
  note: Schema.NullOr(Schema.String),
  original: Schema.optional(OriginalAmount),
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
