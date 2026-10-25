import { CurrentSpace, CurrentUser, SpaceContext } from "@bida/api-contract";
import { Effect, Layer } from "effect";
import { HttpServerRequest } from "effect/http";
import { SpacesService } from "./spaces.service.ts";

/**
 * Implements the `SpaceContext` middleware: the `X-Space-Id` header picks the
 * space, no header means the user's first one. Requires `SpacesService`, and
 * the request has to be signed in already.
 */
export const SpaceContextLive = Layer.effect(
  SpaceContext,
  Effect.gen(function* () {
    const spaces = yield* SpacesService;
    return SpaceContext.of((httpEffect) =>
      Effect.gen(function* () {
        const request = yield* HttpServerRequest.HttpServerRequest;
        const { user } = yield* CurrentUser;
        const space = yield* spaces.resolveFor(
          user.id,
          request.headers["x-space-id"],
        );
        return yield* Effect.provideService(httpEffect, CurrentSpace, space);
      }),
    );
  }),
);
