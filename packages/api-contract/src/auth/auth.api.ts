import { Schema } from "effect";
import { HttpApiEndpoint, HttpApiGroup, OpenApi } from "effect/http-api";
import { wire } from "../errors.ts";
import { InvalidLogin, TooManyRequests } from "./auth.errors.ts";
import { Authenticated, Transport } from "./authenticated.ts";
import { Email, UserJson } from "./user.model.ts";

export const RequestLink = Schema.Struct({ email: Email }).annotate({
  identifier: "RequestLink",
});

export const VerifyCode = Schema.Struct({
  email: Email,
  code: Schema.String.check(Schema.isPattern(/^\d{6}$/)),
  transport: Transport,
}).annotate({ identifier: "VerifyCode" });

export const VerifyToken = Schema.Struct({
  token: Schema.String.check(Schema.isMinLength(20), Schema.isMaxLength(200)),
  transport: Transport,
}).annotate({ identifier: "VerifyToken" });

export const GoogleSignIn = Schema.Struct({
  idToken: Schema.String.check(
    Schema.isMinLength(20),
    Schema.isMaxLength(4096),
  ),
  transport: Transport,
}).annotate({ identifier: "GoogleSignIn" });

export const AuthResult = Schema.Struct({
  user: UserJson,
  /** Only with the `token` transport. Send it as `Authorization: Bearer`. */
  token: Schema.optional(Schema.String),
}).annotate({ identifier: "AuthResult" });

export class AuthApi extends HttpApiGroup.make("auth")
  .add(
    HttpApiEndpoint.post("requestLink", "/magic-link", {
      payload: RequestLink,
      error: wire(TooManyRequests),
    }).annotateMerge(
      OpenApi.annotations({
        summary: "E-mail a sign-in link and code",
        description:
          "Always answers 204, whether or not the address has an account. The e-mail has a link (opened in the browser app) and a 6-digit code (typed in the mobile app), valid for 15 minutes.",
      }),
    ),
    HttpApiEndpoint.post("verifyCode", "/magic-link/code", {
      payload: VerifyCode,
      success: AuthResult,
      error: wire(InvalidLogin),
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Sign in with the code from the e-mail",
        description:
          "Creates the account on the first sign-in. A code stops working after 5 wrong tries.",
      }),
    ),
    HttpApiEndpoint.post("verifyToken", "/magic-link/token", {
      payload: VerifyToken,
      success: AuthResult,
      error: wire(InvalidLogin),
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Sign in with the token from the e-mailed link",
      }),
    ),
    HttpApiEndpoint.post("googleSignIn", "/google", {
      payload: GoogleSignIn,
      success: AuthResult,
      error: wire(InvalidLogin),
    }).annotateMerge(
      OpenApi.annotations({
        summary: "Sign in with a Google ID token",
        description:
          "The app signs in with Google and sends the ID token it got. The token has to be for one of this server's Google client ids and its e-mail address verified by Google. Creates the account on the first sign-in; an account with the same address is the same account.",
      }),
    ),
    HttpApiEndpoint.get("me", "/me", {
      success: UserJson,
    })
      .middleware(Authenticated)
      .annotateMerge(OpenApi.annotations({ summary: "The signed-in user" })),
    HttpApiEndpoint.post("logout", "/logout", {})
      .middleware(Authenticated)
      .annotateMerge(
        OpenApi.annotations({
          summary: "End this session",
          description:
            "The token stops working at once and the cookie is cleared.",
        }),
      ),
  )
  .prefix("/auth")
  .annotateMerge(OpenApi.annotations({ title: "Auth" })) {}
