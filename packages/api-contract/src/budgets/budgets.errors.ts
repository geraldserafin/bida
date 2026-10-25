import { Schema } from "effect";
import { CategoryId } from "../categories/index.ts";
import { PeriodId } from "./budgets.model.ts";

export class PeriodNotFound extends Schema.TaggedError<PeriodNotFound>()(
  "PeriodNotFound",
  { id: PeriodId },
  { httpApiStatus: 404 },
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
