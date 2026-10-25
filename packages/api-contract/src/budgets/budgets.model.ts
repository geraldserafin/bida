import { Schema } from "effect";
import { Model } from "effect/schema";
import { CategoryId } from "../categories/index.ts";
import { Currency } from "../currency/index.ts";
import { Money } from "../currency/money.ts";
import { IsoDate, Name } from "../text.ts";
import { Uuid } from "../uuid.ts";

export const PeriodId = Uuid.pipe(Schema.brand("PeriodId"));
export type PeriodId = typeof PeriodId.Type;

export const EnvelopeId = Uuid.pipe(Schema.brand("EnvelopeId"));
export type EnvelopeId = typeof EnvelopeId.Type;

/** A budgeting period, e.g. "July 2026", with the income to be distributed. */
export class Period extends Model.Class<Period>("Period")({
  id: Model.UuidV4Insert(PeriodId),
  name: Name,
  startDate: IsoDate,
  endDate: IsoDate,
  incomeMinor: Money,
  /** All amounts of the period are in this currency. */
  currency: Currency,
  createdAt: Model.DateTimeInsertFromDate,
  updatedAt: Model.DateTimeUpdateFromDate,
}) {}

/** The part of a period's income planned for one category. */
export class Envelope extends Model.Class<Envelope>("Envelope")({
  id: Model.UuidV4Insert(EnvelopeId),
  periodId: PeriodId,
  categoryId: CategoryId,
  plannedMinor: Money,
  createdAt: Model.DateTimeInsertFromDate,
  updatedAt: Model.DateTimeUpdateFromDate,
}) {}

export const PeriodJson = Period.json.annotate({ identifier: "Period" });
export const EnvelopeJson = Envelope.json.annotate({ identifier: "Envelope" });

/** A period with its envelopes and the totals derived from them. */
export const PeriodDetail = Schema.Struct({
  period: PeriodJson,
  envelopes: Schema.Array(EnvelopeJson),
  plannedMinor: Money,
  /** Income minus planned. Negative when over-allocated. */
  unallocatedMinor: Schema.Int,
}).annotate({ identifier: "PeriodDetail" });
export type PeriodDetail = typeof PeriodDetail.Type;

/** How much of a period's income goes to a category. */
export const EnvelopePlan = Schema.Struct({
  categoryId: CategoryId,
  plannedMinor: Money,
}).annotate({ identifier: "EnvelopePlan" });
export type EnvelopePlan = typeof EnvelopePlan.Type;

export const CreatePeriod = Schema.Struct({
  name: Name,
  startDate: IsoDate,
  endDate: IsoDate,
  incomeMinor: Money,
  /** Defaults to the space's default currency. */
  currency: Schema.optional(Currency),
  /** Initial plan. Entries with a zero amount are ignored. */
  envelopes: Schema.Array(EnvelopePlan).check(Schema.isMaxLength(500)),
}).annotate({ identifier: "CreatePeriod" });
export type CreatePeriod = typeof CreatePeriod.Type;

/**
 * Sets a period's income and envelope amounts. Entries are applied one by one:
 * a positive amount creates or updates the envelope, zero removes it (or keeps
 * it at zero when expenses already point at it). Categories that are not listed
 * stay untouched.
 */
export const SetPlan = Schema.Struct({
  incomeMinor: Money,
  envelopes: Schema.Array(EnvelopePlan).check(Schema.isMaxLength(500)),
}).annotate({ identifier: "SetPlan" });
export type SetPlan = typeof SetPlan.Type;

/** Renames a period and moves its dates. The currency and the plan stay. */
export const UpdatePeriod = Schema.Struct({
  name: Name,
  startDate: IsoDate,
  endDate: IsoDate,
}).annotate({ identifier: "UpdatePeriod" });
export type UpdatePeriod = typeof UpdatePeriod.Type;
