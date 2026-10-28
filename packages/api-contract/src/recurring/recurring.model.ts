import { Schema } from "effect";
import { Model } from "effect/schema";
import { UserId } from "../auth/user.model.ts";
import { EnvelopeId } from "../envelopes/envelope.model.ts";
import { PositiveMoney } from "../money.ts";
import { IsoDate, Note } from "../text.ts";
import { Uuid } from "../uuid.ts";

export const RecurringRuleId = Uuid.pipe(Schema.brand("RecurringRuleId"));
export type RecurringRuleId = typeof RecurringRuleId.Type;

export const Frequency = Schema.Literals(["weekly", "monthly"]);
export type Frequency = typeof Frequency.Type;

/** An expense that repeats, e.g. rent. Applying it adds one expense. */
export class RecurringRule extends Model.Class<RecurringRule>("RecurringRule")({
  id: Model.UuidV4Insert(RecurringRuleId),
  /** The user whose expenses the rule produces. */
  userId: Model.Field({
    select: UserId,
    insert: UserId,
    update: UserId,
    json: UserId,
  }),
  envelopeId: EnvelopeId,
  /** Amount in minor units (grosze), always positive. */
  amountMinor: PositiveMoney,
  frequency: Frequency,
  note: Schema.NullOr(Note),
  active: Schema.Boolean,
  createdAt: Model.DateTimeInsertFromDate,
  updatedAt: Model.DateTimeUpdateFromDate,
}) {}

export const RecurringRuleJson = RecurringRule.json.annotate({
  identifier: "RecurringRule",
});

export const SaveRecurringRule = Schema.Struct({
  envelopeId: EnvelopeId,
  amountMinor: PositiveMoney,
  frequency: Frequency,
  note: Schema.NullOr(Note),
  active: Schema.Boolean,
}).annotate({ identifier: "SaveRecurringRule" });
export type SaveRecurringRule = typeof SaveRecurringRule.Type;

/** The stretch of time to apply the rules to, usually the current month. */
export const ApplyRecurring = Schema.Struct({
  from: IsoDate,
  to: IsoDate,
}).annotate({ identifier: "ApplyRecurring" });
export type ApplyRecurring = typeof ApplyRecurring.Type;

export const ApplyResult = Schema.Struct({
  /** Recurring incomes that were added as income. */
  incomes: Schema.Int,
  /** Allocation rules that were carried out as allocations. */
  allocations: Schema.Int,
  /** Recurring expenses that were added as expenses. */
  expenses: Schema.Int,
  /**
   * Allocation rules that could not be carried out, because the envelope did
   * not have the money or is not the user's any more. Always 0 for a preview.
   */
  skipped: Schema.Int,
}).annotate({ identifier: "ApplyResult" });
export type ApplyResult = typeof ApplyResult.Type;
