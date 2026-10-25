import { Authenticated, CurrentUser, Unauthorized } from "@bida/api-contract";
import { Effect, Layer, Redacted } from "effect";
import { HttpServerRequest } from "effect/http";
import { AppConfig } from "../../platform/config.ts";
import { AuthService } from "./auth.service.ts";

const SAFE_METHODS = new Set(["GET", "HEAD", "OPTIONS"]);

/**
 * Implements the `Authenticated` middleware. A bearer token is checked as it
 * is. A cookie is sent by the browser on its own, so a request that changes
 * something has to come from one of the allowed origins, or another site
 * could make the browser act on the user's behalf.
 */
export const AuthenticatedLive = Layer.effect(
  Authenticated,
  Effect.gen(function* () {
    const auth = yield* AuthService;
    const { corsOrigins } = yield* AppConfig;

    return Authenticated.of({
      bearer: (httpEffect, { credential }) =>
        auth
          .authenticate(Redacted.value(credential))
          .pipe(
            Effect.flatMap((current) =>
              Effect.provideService(httpEffect, CurrentUser, current),
            ),
          ),
      cookie: (httpEffect, { credential }) =>
        Effect.gen(function* () {
          const request = yield* HttpServerRequest.HttpServerRequest;
          const origin = request.headers.origin;
          if (
            !SAFE_METHODS.has(request.method) &&
            (origin === undefined || !corsOrigins.includes(origin))
          )
            return yield* new Unauthorized();
          const current = yield* auth.authenticate(Redacted.value(credential));
          return yield* Effect.provideService(httpEffect, CurrentUser, current);
        }),
    });
  }),
);
