import { Schema } from "effect";

export class ContributionNotFound extends Schema.TaggedError<ContributionNotFound>()(
  "ContributionNotFound",
  { id: Schema.String },
  { httpApiStatus: 404 },
) {}
