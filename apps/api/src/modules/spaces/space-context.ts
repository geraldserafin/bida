import {
  CurrentMember,
  CurrentSpace,
  CurrentUser,
  SpaceContext,
} from "@bida/api-contract";
import { Effect, Layer } from "effect";
import { HttpServerRequest } from "effect/http";
import { SpacesService } from "./spaces.service.ts";

/**
 * Implements the `SpaceContext` middleware: the `X-Space-Id` header picks the
 * space, no header means the user's first one (their personal space). The
 * user's role in it is provided too. Requires `SpacesService`, and the request
 * has to be signed in already.
 */
export const SpaceContextLive = Layer.effect(
  SpaceContext,
  Effect.gen(function* () {
    const spaces = yield* SpacesService;
    return SpaceContext.of((httpEffect) =>
      Effect.gen(function* () {
        const request = yield* HttpServerRequest.HttpServerRequest;
        const { user } = yield* CurrentUser;
        const { space, role } = yield* spaces.resolveFor(
          user.id,
          request.headers["x-space-id"],
        );
        return yield* httpEffect.pipe(
          Effect.provideService(CurrentSpace, space),
          Effect.provideService(CurrentMember, { userId: user.id, role }),
        );
      }),
    );
  }),
);
