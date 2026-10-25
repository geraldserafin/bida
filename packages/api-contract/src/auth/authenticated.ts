import { Schema } from "effect";
import { HttpApiMiddleware, HttpApiSecurity } from "effect/http-api";
import { wire } from "../errors.ts";
import { Unauthorized } from "./auth.errors.ts";
import type { CurrentUser } from "./user.model.ts";

/** Name of the cookie the browser app keeps its session in. */
export const SESSION_COOKIE = "bida_session";

/**
 * Requires a signed-in user and provides them as `CurrentUser`. The session
 * token comes either in an `Authorization: Bearer` header (the mobile app) or
 * in the session cookie (the browser app).
 */
export class Authenticated extends HttpApiMiddleware.Service<
  Authenticated,
  {
    provides: CurrentUser;
    requires: never;
  }
>()("bida/auth/Authenticated", {
  error: wire(Unauthorized),
  security: {
    bearer: HttpApiSecurity.bearer,
    cookie: HttpApiSecurity.apiKey({ key: SESSION_COOKIE, in: "cookie" }),
  },
}) {}

/** How the app wants to hold the session: in the response or in a cookie. */
export const Transport = Schema.Literals(["token", "cookie"]).annotate({
  identifier: "Transport",
  description:
    "`token` returns the session token in the response body (mobile apps); `cookie` sets it as an HTTP-only cookie instead (browser apps).",
});
export type Transport = typeof Transport.Type;
