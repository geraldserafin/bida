import { Schema } from "effect";
import { Model } from "effect/schema";
import { UserId } from "../auth/user.model.ts";
import { PeriodId } from "../budgets/index.ts";
import { PositiveMoney } from "../currency/money.ts";
import { Note } from "../text.ts";
import { Uuid } from "../uuid.ts";

export const ContributionId = Uuid.pipe(Schema.brand("ContributionId"));
export type ContributionId = typeof ContributionId.Type;

// Client-provided instant: a Date in the database, an ISO string in JSON.
const ContributedAt = Model.Field({
  select: Schema.DateTimeUtcFromDate,
  insert: Schema.DateTimeUtcFromDate,
  update: Schema.DateTimeUtcFromDate,
  json: Schema.DateTimeUtcFromString,
  jsonCreate: Schema.DateTimeUtcFromString,
  jsonUpdate: Schema.DateTimeUtcFromString,
});

/**
 * Money that came into the budget of a shared space in a period: what was
 * actually paid in, next to the income that was planned. In the currency of
 * the period.
 */
export class Contribution extends Model.Class<Contribution>("Contribution")({
  id: Model.UuidV4Insert(ContributionId),
  periodId: PeriodId,
  /** Who paid in. Empty for money from outside, and when that person's account is gone. */
  userId: Schema.NullOr(UserId),
  amountMinor: PositiveMoney,
  contributedAt: ContributedAt,
  note: Schema.NullOr(Note),
  createdAt: Model.DateTimeInsertFromDate,
}) {}

export const ContributionJson = Contribution.json.annotate({
  identifier: "Contribution",
});

export const AddContribution = Schema.Struct({
  /** In the currency of the period. */
  amountMinor: PositiveMoney,
  contributedAt: Schema.DateTimeUtcFromString,
  note: Schema.NullOr(Note),
  /** Set when the money is not yours, e.g. cash from somebody outside. */
  external: Schema.optional(Schema.Boolean),
}).annotate({ identifier: "AddContribution" });
export type AddContribution = typeof AddContribution.Type;
