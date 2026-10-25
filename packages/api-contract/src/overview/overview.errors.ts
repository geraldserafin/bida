import { Schema } from "effect";

export class InvalidTimeZone extends Schema.TaggedError<InvalidTimeZone>()(
  "InvalidTimeZone",
  { timeZone: Schema.String },
  { httpApiStatus: 422 },
) {}

export class InvalidRange extends Schema.TaggedError<InvalidRange>()(
  "InvalidRange",
  { from: Schema.String, to: Schema.String },
  { httpApiStatus: 422 },
) {}
