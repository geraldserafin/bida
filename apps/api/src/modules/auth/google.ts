import { createPublicKey, verify } from "node:crypto";
import { InvalidLogin } from "@bida/api-contract";
import { Context, Effect, Layer, Schema } from "effect";
import { AppConfig } from "../../platform/config.ts";

/** What Google says about the person who signed in. */
export interface GoogleProfile {
  /** Stays the same for the person even if their address changes. */
  readonly subject: string;
  readonly email: string;
  readonly name: string | null;
}

/** A public key of Google, in the JSON Web Key form it publishes them in. */
export interface GoogleKey {
  readonly kid: string;
  readonly [field: string]: unknown;
}

/** What the verifier needs from the outside; replaced in tests. */
export interface GoogleOptions {
  /** Fetches Google's current signing keys (and how long they stay valid). */
  readonly loadKeys: Effect.Effect<{
    readonly keys: ReadonlyArray<GoogleKey>;
    readonly ttlSeconds: number;
  }>;
  /** GETs a JSON document from Google, with an access token when given. */
  readonly getJson: (
    url: string,
    bearer?: string,
  ) => Effect.Effect<unknown, unknown>;
  /** OAuth client ids of our apps; a token for any other is refused. */
  readonly clientIds: ReadonlyArray<string>;
  readonly now?: () => number;
}

const CERTS_URL = "https://www.googleapis.com/oauth2/v3/certs";
const TOKENINFO_URL = "https://oauth2.googleapis.com/tokeninfo";
const USERINFO_URL = "https://openidconnect.googleapis.com/v1/userinfo";
const ISSUERS = ["accounts.google.com", "https://accounts.google.com"];

const Header = Schema.Struct({ alg: Schema.String, kid: Schema.String });
const Verified = Schema.Union([Schema.Boolean, Schema.Literal("true")]);
const Claims = Schema.Struct({
  iss: Schema.String,
  aud: Schema.String,
  sub: Schema.String,
  exp: Schema.Number,
  email: Schema.String,
  email_verified: Verified,
  name: Schema.optional(Schema.String),
});
/** Google's answer about an access token: who it was issued to and for. */
const TokenInfo = Schema.Struct({
  aud: Schema.String,
  sub: Schema.String,
  email: Schema.String,
  email_verified: Verified,
  expires_in: Schema.NumberFromString,
});
const UserInfo = Schema.Struct({ name: Schema.optional(Schema.String) });

const decodeJson = <
  S extends Schema.Top & { readonly DecodingServices: never },
>(
  schema: S,
  part: string,
) =>
  Schema.decodeUnknownEffect(Schema.fromJsonString(schema))(
    Buffer.from(part, "base64url").toString("utf8"),
  );

const displayName = (name: string | undefined) =>
  name?.trim() ? name.trim().slice(0, 200) : null;

/**
 * Checks what an app got from Google sign-in: an ID token (Android) or an
 * access token (browser). Either has to be for one of our client ids, with the
 * address verified by Google.
 */
export class GoogleVerifier extends Context.Service<
  GoogleVerifier,
  {
    /** Checks the signature and the claims of an ID token. */
    verify(idToken: string): Effect.Effect<GoogleProfile, InvalidLogin>;
    /**
     * Asks Google whom an access token was issued to. The token has to be
     * for our client: one issued to another app must not sign anybody in.
     */
    verifyAccessToken(
      accessToken: string,
    ): Effect.Effect<GoogleProfile, InvalidLogin>;
  }
>()("bida/auth/GoogleVerifier") {
  static readonly layerWith = (options: GoogleOptions) =>
    Layer.sync(GoogleVerifier, () => {
      const { loadKeys, getJson, clientIds } = options;
      const now = options.now ?? Date.now;
      let cached: { keys: ReadonlyArray<GoogleKey>; until: number } = {
        keys: [],
        until: 0,
      };
      const keyFor = Effect.fn("GoogleVerifier.keyFor")(function* (
        kid: string,
      ) {
        const known = () => cached.keys.find((key) => key.kid === kid);
        if (now() < cached.until && known() !== undefined) return known();
        // expired, or a key we have not seen: Google rotates them
        const loaded = yield* loadKeys;
        cached = { keys: loaded.keys, until: now() + loaded.ttlSeconds * 1000 };
        return known();
      });

      const check = Effect.fn("GoogleVerifier.verify")(function* (
        idToken: string,
      ) {
        const [header, payload, signature, ...extra] = idToken.split(".");
        if (!header || !payload || !signature || extra.length > 0)
          return yield* new InvalidLogin();
        const head = yield* decodeJson(Header, header);
        // only what Google signs with; never `none` or a shared-secret scheme
        if (head.alg !== "RS256") return yield* new InvalidLogin();
        const jwk = yield* keyFor(head.kid);
        if (jwk === undefined) return yield* new InvalidLogin();
        const signed = verify(
          "RSA-SHA256",
          Buffer.from(`${header}.${payload}`),
          createPublicKey({ key: jwk as never, format: "jwk" }),
          Buffer.from(signature, "base64url"),
        );
        if (!signed) return yield* new InvalidLogin();

        const claims = yield* decodeJson(Claims, payload);
        if (
          !ISSUERS.includes(claims.iss) ||
          !clientIds.includes(claims.aud) ||
          claims.exp * 1000 <= now() ||
          claims.email_verified === false ||
          claims.email === "" ||
          claims.sub === ""
        )
          return yield* new InvalidLogin();
        return {
          subject: claims.sub,
          email: claims.email,
          name: displayName(claims.name),
        } satisfies GoogleProfile;
      });

      const checkAccessToken = Effect.fn("GoogleVerifier.verifyAccessToken")(
        function* (accessToken: string) {
          const info = yield* getJson(
            `${TOKENINFO_URL}?access_token=${encodeURIComponent(accessToken)}`,
          ).pipe(Effect.flatMap(Schema.decodeUnknownEffect(TokenInfo)));
          if (
            !clientIds.includes(info.aud) ||
            info.expires_in <= 0 ||
            info.email_verified === false ||
            info.email === "" ||
            info.sub === ""
          )
            return yield* new InvalidLogin();
          // the name is a nicety: without it the person still signs in
          const profile = yield* getJson(USERINFO_URL, accessToken).pipe(
            Effect.flatMap(Schema.decodeUnknownEffect(UserInfo)),
            Effect.catch(() => Effect.succeed({ name: undefined })),
          );
          return {
            subject: info.sub,
            email: info.email,
            name: displayName(profile.name),
          } satisfies GoogleProfile;
        },
      );

      return GoogleVerifier.of({
        // anything wrong with a token, however it is wrong, is a refusal
        verify: (idToken) =>
          check(idToken).pipe(
            Effect.catch(() => Effect.fail(new InvalidLogin())),
          ),
        verifyAccessToken: (accessToken) =>
          checkAccessToken(accessToken).pipe(
            Effect.catch(() => Effect.fail(new InvalidLogin())),
          ),
      });
    });

  /** Talks to Google over HTTPS. Without client ids nothing passes. */
  static readonly layer = Layer.unwrap(
    AppConfig.pipe(
      Effect.map(({ googleClientIds }) => {
        const getJson = (url: string, bearer?: string) =>
          Effect.tryPromise(async () => {
            const response = await fetch(url, {
              headers: bearer ? { authorization: `Bearer ${bearer}` } : {},
              signal: AbortSignal.timeout(5000),
            });
            if (!response.ok) throw new Error(`google: ${response.status}`);
            return (await response.json()) as unknown;
          });
        return GoogleVerifier.layerWith({
          loadKeys: Effect.tryPromise(async () => {
            const response = await fetch(CERTS_URL, {
              signal: AbortSignal.timeout(5000),
            });
            if (!response.ok) throw new Error(`certs: ${response.status}`);
            const body = (await response.json()) as {
              keys: ReadonlyArray<GoogleKey>;
            };
            const age = /max-age=(\d+)/.exec(
              response.headers.get("cache-control") ?? "",
            );
            return { keys: body.keys, ttlSeconds: Number(age?.[1] ?? 3600) };
          }).pipe(Effect.orDie),
          getJson,
          clientIds: googleClientIds,
        });
      }),
    ),
  );
}
