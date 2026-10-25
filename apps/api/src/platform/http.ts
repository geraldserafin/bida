import { ByteSize, Effect } from "effect";
import { HttpServerRequest } from "effect/http";

/** Largest request body the server reads. Import files are the big ones. */
export const MAX_BODY = ByteSize.mebibytes(8);

/** Server middleware that caps how much of a request body is read. */
export const bodyLimit = <A, E, R>(app: Effect.Effect<A, E, R>) =>
  Effect.provideService(app, HttpServerRequest.MaxBodySize, MAX_BODY);
