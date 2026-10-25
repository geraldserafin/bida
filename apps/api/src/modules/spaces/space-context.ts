import { CurrentSpace, SpaceContext } from "@bida/api-contract";
import { Effect, Layer } from "effect";
import { HttpServerRequest } from "effect/http";
import { SpacesService } from "./spaces.service.ts";

/**
 * Implements the `SpaceContext` middleware: the `X-Space-Id` header picks the
 * space, no header means the default one. Requires `SpacesService`.
 */
export const SpaceContextLive = Layer.effect(
  SpaceContext,
  Effect.gen(function* () {
    const spaces = yield* SpacesService;
    return SpaceContext.of((httpEffect) =>
      Effect.gen(function* () {
        const request = yield* HttpServerRequest.HttpServerRequest;
        const space = yield* spaces.resolve(request.headers["x-space-id"]);
        return yield* Effect.provideService(httpEffect, CurrentSpace, space);
      }),
    );
  }),
);
