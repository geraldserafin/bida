import { HttpApiMiddleware } from "effect/http-api";
import type { CurrentUser } from "../auth/user.model.ts";
import { wire } from "../errors.ts";
import type { CurrentSpace } from "./space.model.ts";
import { SpaceNotFound } from "./spaces.errors.ts";

/**
 * Picks the space a request works in from the `X-Space-Id` header, which has
 * to be a space the signed-in user is a member of. Without the header it is
 * the user's first space. Needs `Authenticated` to run before it.
 */
export class SpaceContext extends HttpApiMiddleware.Service<
  SpaceContext,
  {
    provides: CurrentSpace;
    requires: CurrentUser;
  }
>()("bida/spaces/SpaceContext", {
  error: wire(SpaceNotFound),
}) {}
