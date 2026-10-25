import { HttpApiMiddleware } from "effect/http-api";
import { wire } from "../errors.ts";
import type { CurrentSpace } from "./space.model.ts";
import { SpaceNotFound } from "./spaces.errors.ts";

/**
 * Picks the space a request works in from the `X-Space-Id` header and falls
 * back to the default space when it is missing. Later this is where
 * membership of the signed-in user gets checked.
 */
export class SpaceContext extends HttpApiMiddleware.Service<
  SpaceContext,
  {
    provides: CurrentSpace;
    requires: never;
  }
>()("bida/spaces/SpaceContext", {
  error: wire(SpaceNotFound),
}) {}
