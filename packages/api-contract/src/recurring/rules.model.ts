import { Schema } from "effect";
import { Model } from "effect/schema";
import { UserId } from "../auth/user.model.ts";
import { EnvelopeId } from "../envelopes/envelope.model.ts";
import { PositiveMoney } from "../money.ts";
import { Note } from "../text.ts";
import { Uuid } from "../uuid.ts";

/**
 * The day of the month a rule falls on. Up to the 28th, so every month has it
 * and every stretch of a month (which is at least 28 days) contains it.
 */
export const DayOfMonth = Schema.Int.check(
  Schema.isBetween({ minimum: 1, maximum: 28 }),
);

const ServerUser = Model.Field({
  select: UserId,
  insert: UserId,
  update: UserId,
  json: UserId,
});

export const RecurringIncomeId = Uuid.pipe(Schema.brand("RecurringIncomeId"));
export type RecurringIncomeId = typeof RecurringIncomeId.Type;

/** Money that comes in every month, e.g. a salary. Applying it adds an income. */
export class RecurringIncome extends Model.Class<RecurringIncome>(
  "RecurringIncome",
)({
  id: Model.UuidV4Insert(RecurringIncomeId),
  userId: ServerUser,
  amountMinor: PositiveMoney,
  dayOfMonth: DayOfMonth,
  note: Schema.NullOr(Note),
  active: Schema.Boolean,
  createdAt: Model.DateTimeInsertFromDate,
  updatedAt: Model.DateTimeUpdateFromDate,
}) {}

export const RecurringIncomeJson = RecurringIncome.json.annotate({
  identifier: "RecurringIncome",
});

export const SaveRecurringIncome = Schema.Struct({
  amountMinor: PositiveMoney,
  dayOfMonth: DayOfMonth,
  note: Schema.NullOr(Note),
  active: Schema.Boolean,
}).annotate({ identifier: "SaveRecurringIncome" });
export type SaveRecurringIncome = typeof SaveRecurringIncome.Type;

export class RecurringIncomeNotFound extends Schema.TaggedError<RecurringIncomeNotFound>()(
  "RecurringIncomeNotFound",
  { id: RecurringIncomeId },
  { httpApiStatus: 404 },
) {}

export const AllocationRuleId = Uuid.pipe(Schema.brand("AllocationRuleId"));
export type AllocationRuleId = typeof AllocationRuleId.Type;

/**
 * Money that goes into an envelope every month, e.g. "1 000 zł to Home on the
 * 1st". Applying it adds an allocation.
 */
export class AllocationRule extends Model.Class<AllocationRule>(
  "AllocationRule",
)({
  id: Model.UuidV4Insert(AllocationRuleId),
  userId: ServerUser,
  envelopeId: EnvelopeId,
  amountMinor: PositiveMoney,
  dayOfMonth: DayOfMonth,
  note: Schema.NullOr(Note),
  active: Schema.Boolean,
  createdAt: Model.DateTimeInsertFromDate,
  updatedAt: Model.DateTimeUpdateFromDate,
}) {}

export const AllocationRuleJson = AllocationRule.json.annotate({
  identifier: "AllocationRule",
});

export const SaveAllocationRule = Schema.Struct({
  envelopeId: EnvelopeId,
  amountMinor: PositiveMoney,
  dayOfMonth: DayOfMonth,
  note: Schema.NullOr(Note),
  active: Schema.Boolean,
}).annotate({ identifier: "SaveAllocationRule" });
export type SaveAllocationRule = typeof SaveAllocationRule.Type;

export class AllocationRuleNotFound extends Schema.TaggedError<AllocationRuleNotFound>()(
  "AllocationRuleNotFound",
  { id: AllocationRuleId },
  { httpApiStatus: 404 },
) {}
