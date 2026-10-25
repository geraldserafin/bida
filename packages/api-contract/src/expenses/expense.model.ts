import { Schema } from "effect";
import { Model } from "effect/schema";
import { UserId } from "../auth/user.model.ts";
import { EnvelopeId } from "../envelopes/envelope.model.ts";
import { PositiveMoney } from "../money.ts";
import { RecurringRuleId } from "../recurring/recurring.model.ts";
import { Note } from "../text.ts";
import { Uuid } from "../uuid.ts";

export const ExpenseId = Uuid.pipe(Schema.brand("ExpenseId"));
export type ExpenseId = typeof ExpenseId.Type;

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
  /** Who recorded it. */
  createdBy: Model.Field({
    select: UserId,
    insert: UserId,
    update: UserId,
    json: UserId,
  }),
  amountMinor: PositiveMoney,
  spentAt: SpentAt,
  note: Schema.NullOr(Note),
  /** Set when the expense was generated from a recurring rule. */
  recurringId: Schema.NullOr(RecurringRuleId),
  createdAt: Model.DateTimeInsertFromDate,
  updatedAt: Model.DateTimeUpdateFromDate,
}) {}

export const ExpenseJson = Expense.json.annotate({ identifier: "Expense" });

export const CreateExpense = Schema.Struct({
  envelopeId: EnvelopeId,
  amountMinor: PositiveMoney,
  spentAt: Schema.DateTimeUtcFromString,
  note: Schema.NullOr(Note),
}).annotate({ identifier: "CreateExpense" });
export type CreateExpense = typeof CreateExpense.Type;

/** Replaces the editable fields. */
export const UpdateExpense = Schema.Struct({
  envelopeId: EnvelopeId,
  amountMinor: PositiveMoney,
  spentAt: Schema.DateTimeUtcFromString,
  note: Schema.NullOr(Note),
}).annotate({ identifier: "UpdateExpense" });
export type UpdateExpense = typeof UpdateExpense.Type;
