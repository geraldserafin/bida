import { Schema } from "effect";

/** The document is well formed but its data does not hold together. */
export class InvalidImport extends Schema.TaggedError<InvalidImport>()(
  "InvalidImport",
  { reason: Schema.String },
  { httpApiStatus: 422 },
) {}

export class InvalidCsv extends Schema.TaggedError<InvalidCsv>()(
  "InvalidCsv",
  { line: Schema.Int, reason: Schema.String },
  { httpApiStatus: 422 },
) {}
