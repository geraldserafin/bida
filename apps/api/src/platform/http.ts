import { ByteSize, Effect } from "effect";
import { HttpMiddleware, HttpServerRequest } from "effect/http";

/** Largest request body the server reads. Import files are the big ones. */
export const MAX_BODY = ByteSize.mebibytes(8);

/** Server middleware that caps how much of a request body is read. */
export const bodyLimit = <A, E, R>(app: Effect.Effect<A, E, R>) =>
  Effect.provideService(app, HttpServerRequest.MaxBodySize, MAX_BODY);

/**
 * Server middleware that lets browser apps served from [origins] call the API.
 * Without origins it does nothing, so no other site can read the responses.
 */
export const corsFor = (origins: ReadonlyArray<string>) =>
  origins.length === 0
    ? HttpMiddleware.make((app) => app)
    : HttpMiddleware.cors({ allowedOrigins: origins, maxAge: 600 });
