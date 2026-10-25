import { Schema } from "effect";

export class SpaceNotFound extends Schema.TaggedError<SpaceNotFound>()(
  "SpaceNotFound",
  { id: Schema.String },
  { httpApiStatus: 404 },
) {}
