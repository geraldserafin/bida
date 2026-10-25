import { Schema } from "effect";
import { HttpApiEndpoint, HttpApiGroup, OpenApi } from "effect/http-api";
import { Authenticated } from "../auth/authenticated.ts";
import { wire } from "../errors.ts";
import { IsoDate } from "../text.ts";
import { InvalidRange, InvalidTimeZone } from "./overview.errors.ts";
import { MonthSummary, Overview } from "./overview.model.ts";

/** IANA time zone that decides on which day an expense falls. */
const TimeZone = Schema.String.check(Schema.isMaxLength(64));

export class OverviewApi extends HttpApiGroup.make("overview")
  .add(
    HttpApiEndpoint.get("get", "/overview", {
      query: {
        from: IsoDate,
        to: IsoDate,
        /** Defaults to `Europe/Warsaw`. */
        timeZone: Schema.optional(TimeZone),
      },
      success: Overview,
      error: [wire(InvalidTimeZone), wire(InvalidRange)],
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Money over a stretch of time",
        description:
          "Income, what was put into envelopes and spent between the two days (both included), the pool that is left, and the figures of every envelope. Balances roll over from earlier days.",
      }),
    ),
    HttpApiEndpoint.get("months", "/overview/months", {
      query: {
        /** Day of the month a budget month starts on, 1 to 28. */
        startDay: Schema.optional(
          Schema.NumberFromString.check(
            Schema.isInt(),
            Schema.isBetween({ minimum: 1, maximum: 28 }),
          ),
        ),
        timeZone: Schema.optional(TimeZone),
      },
      success: Schema.Array(MonthSummary),
      error: wire(InvalidTimeZone),
    }).annotateMerge(
      OpenApi.annotations({
        summary: "History by month",
        description:
          "Every month from the first with activity until now, newest first.",
      }),
    ),
  )
  .middleware(Authenticated)
  .annotateMerge(OpenApi.annotations({ title: "Overview" })) {}
