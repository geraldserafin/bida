import { Schema } from "effect";
import { CategoryId } from "../categories/index.ts";
import { PeriodId } from "./budgets.model.ts";

export class PeriodNotFound extends Schema.TaggedError<PeriodNotFound>()(
  "PeriodNotFound",
  { id: PeriodId },
  { httpApiStatus: 404 },
) {}

/** Somebody edited the period since it was loaded: reload and edit again. */
export class PeriodChanged extends Schema.TaggedError<PeriodChanged>()(
  "PeriodChanged",
  { id: PeriodId },
  { httpApiStatus: 409 },
) {}

/** There is no period yet, so there is no current one. */
export class NoPeriods extends Schema.TaggedError<NoPeriods>()(
  "NoPeriods",
  {},
  { httpApiStatus: 404 },
) {}

export class InvalidPeriodRange extends Schema.TaggedError<InvalidPeriodRange>()(
  "InvalidPeriodRange",
  { startDate: Schema.String, endDate: Schema.String },
  { httpApiStatus: 422 },
) {}

export class EnvelopeAlreadyExists extends Schema.TaggedError<EnvelopeAlreadyExists>()(
  "EnvelopeAlreadyExists",
  { periodId: PeriodId, categoryId: CategoryId },
  { httpApiStatus: 409 },
) {}

export class EnvelopeNotFound extends Schema.TaggedError<EnvelopeNotFound>()(
  "EnvelopeNotFound",
  { id: Schema.String },
  { httpApiStatus: 404 },
) {}
