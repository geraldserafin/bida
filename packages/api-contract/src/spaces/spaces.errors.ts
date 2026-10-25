import { Schema } from "effect";
import { SpaceId } from "./space.model.ts";

export class SpaceNotFound extends Schema.TaggedError<SpaceNotFound>()(
  "SpaceNotFound",
  { id: SpaceId },
  { httpApiStatus: 404 },
) {}
