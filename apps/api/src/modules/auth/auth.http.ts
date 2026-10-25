import { Api, Authenticated, CurrentUser } from "@bida/api-contract";
import { Effect } from "effect";
import { HttpServerRequest } from "effect/http";
import { HttpApiBuilder } from "effect/http-api";
import { AppConfig } from "../../platform/config.ts";
import {
  AuthService,
  SESSION_TTL_SECONDS,
  type SignedIn,
} from "./auth.service.ts";

/** Thin adapter: decoded request in, service call, domain errors out. */
export const AuthHttp = HttpApiBuilder.group(
  Api,
  "auth",
  Effect.fn(function* (handlers) {
    const auth = yield* AuthService;
    const { cookieSecure } = yield* AppConfig;

    const cookieOptions = (maxAge: number) => ({
      secure: cookieSecure,
      httpOnly: true,
      sameSite: "lax" as const,
      path: "/",
      maxAge: `${maxAge} seconds` as const,
    });

    /** The mobile app gets the token to keep; the browser gets a cookie. */
    const respond = Effect.fn("AuthHttp.respond")(function* (
      signedIn: SignedIn,
      transport: "token" | "cookie",
    ) {
      if (transport === "token")
        return { user: signedIn.user, token: signedIn.token };
      yield* HttpApiBuilder.securitySetCookie(
        Authenticated.security.cookie,
        signedIn.token,
        cookieOptions(SESSION_TTL_SECONDS),
      );
      return { user: signedIn.user };
    });

    const userAgent = Effect.map(
      HttpServerRequest.HttpServerRequest,
      (request) => request.headers["user-agent"] ?? null,
    );

    return handlers
      .handle("requestLink", ({ payload }) => auth.requestLink(payload.email))
      .handle("verifyCode", ({ payload }) =>
        Effect.flatMap(userAgent, (agent) =>
          auth.verifyCode(payload.email, payload.code, agent),
        ).pipe(
          Effect.flatMap((signedIn) => respond(signedIn, payload.transport)),
        ),
      )
      .handle("verifyToken", ({ payload }) =>
        Effect.flatMap(userAgent, (agent) =>
          auth.verifyToken(payload.token, agent),
        ).pipe(
          Effect.flatMap((signedIn) => respond(signedIn, payload.transport)),
        ),
      )
      .handle("googleSignIn", ({ payload }) =>
        Effect.flatMap(userAgent, (agent) =>
          auth.signInWithGoogle(payload.idToken, agent),
        ).pipe(
          Effect.flatMap((signedIn) => respond(signedIn, payload.transport)),
        ),
      )
      .handle("googleAccessToken", ({ payload }) =>
        Effect.flatMap(userAgent, (agent) =>
          auth.signInWithGoogleAccessToken(payload.accessToken, agent),
        ).pipe(
          Effect.flatMap((signedIn) => respond(signedIn, payload.transport)),
        ),
      )
      .handle("me", () => Effect.map(CurrentUser, ({ user }) => user))
      .handle("logout", () =>
        Effect.gen(function* () {
          const { sessionId } = yield* CurrentUser;
          yield* auth.logout(sessionId);
          yield* HttpApiBuilder.securitySetCookie(
            Authenticated.security.cookie,
            "",
            cookieOptions(0),
          );
        }),
      );
  }),
);
