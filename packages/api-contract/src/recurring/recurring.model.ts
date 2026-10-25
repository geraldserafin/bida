import { Schema } from "effect";
import { Model } from "effect/schema";
import { CategoryId } from "../categories/index.ts";

export const RecurringRuleId = Schema.String.pipe(
  Schema.brand("RecurringRuleId"),
);
export type RecurringRuleId = typeof RecurringRuleId.Type;

export const Frequency = Schema.Literals(["weekly", "monthly"]);
export type Frequency = typeof Frequency.Type;

/** An expense that repeats, e.g. rent. Applying it adds one expense. */
export class RecurringRule extends Model.Class<RecurringRule>("RecurringRule")({
  id: Model.UuidV4Insert(RecurringRuleId),
  categoryId: CategoryId,
  /** Amount in minor units (grosze), always positive. */
  amountMinor: Schema.Int.check(Schema.isGreaterThan(0)),
  frequency: Frequency,
  note: Schema.NullOr(Schema.String),
  active: Schema.Boolean,
  createdAt: Model.DateTimeInsertFromDate,
  updatedAt: Model.DateTimeUpdateFromDate,
}) {}

export const RecurringRuleJson = RecurringRule.json.annotate({
  identifier: "RecurringRule",
});

export const SaveRecurringRule = Schema.Struct({
  categoryId: CategoryId,
  amountMinor: Schema.Int.check(Schema.isGreaterThan(0)),
  frequency: Frequency,
  note: Schema.NullOr(Schema.String),
  active: Schema.Boolean,
}).annotate({ identifier: "SaveRecurringRule" });
export type SaveRecurringRule = typeof SaveRecurringRule.Type;

export const ApplyResult = Schema.Struct({
  /** Number of expenses that were added. */
  added: Schema.Int,
}).annotate({ identifier: "ApplyResult" });
export type ApplyResult = typeof ApplyResult.Type;
