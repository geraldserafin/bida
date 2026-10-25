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

const CERTS_URL = "https://www.googleapis.com/oauth2/v3/certs";
const ISSUERS = ["accounts.google.com", "https://accounts.google.com"];

const Header = Schema.Struct({ alg: Schema.String, kid: Schema.String });
const Claims = Schema.Struct({
  iss: Schema.String,
  aud: Schema.String,
  sub: Schema.String,
  exp: Schema.Number,
  email: Schema.String,
  email_verified: Schema.Union([Schema.Boolean, Schema.Literal("true")]),
  name: Schema.optional(Schema.String),
});

const decodeJson = <
  S extends Schema.Top & { readonly DecodingServices: never },
>(
  schema: S,
  part: string,
) =>
  Schema.decodeUnknownEffect(Schema.fromJsonString(schema))(
    Buffer.from(part, "base64url").toString("utf8"),
  );

/**
 * Checks the ID token an app got from Google sign-in: signed by Google, meant
 * for one of our client ids, not expired, and the address verified by Google.
 */
export class GoogleVerifier extends Context.Service<
  GoogleVerifier,
  { verify(idToken: string): Effect.Effect<GoogleProfile, InvalidLogin> }
>()("bida/auth/GoogleVerifier") {
  /** [loadKeys] fetches Google's current keys; the verifier caches them. */
  static readonly layerWith = (
    loadKeys: Effect.Effect<{
      readonly keys: ReadonlyArray<GoogleKey>;
      readonly ttlSeconds: number;
    }>,
    clientIds: ReadonlyArray<string>,
    now: () => number = Date.now,
  ) =>
    Layer.sync(GoogleVerifier, () => {
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
          name: claims.name?.trim() ? claims.name.trim().slice(0, 200) : null,
        } satisfies GoogleProfile;
      });

      return GoogleVerifier.of({
        // anything wrong with the token, however it is wrong, is a refusal
        verify: (idToken) =>
          check(idToken).pipe(
            Effect.catch(() => Effect.fail(new InvalidLogin())),
          ),
      });
    });

  /** Fetches Google's keys over HTTPS. Without client ids nothing passes. */
  static readonly layer = Layer.unwrap(
    AppConfig.pipe(
      Effect.map(({ googleClientIds }) =>
        GoogleVerifier.layerWith(
          Effect.tryPromise(async () => {
            const response = await fetch(CERTS_URL);
            if (!response.ok) throw new Error(`certs: ${response.status}`);
            const body = (await response.json()) as {
              keys: ReadonlyArray<GoogleKey>;
            };
            const age = /max-age=(\d+)/.exec(
              response.headers.get("cache-control") ?? "",
            );
            return { keys: body.keys, ttlSeconds: Number(age?.[1] ?? 3600) };
          }).pipe(Effect.orDie),
          googleClientIds,
        ),
      ),
    ),
  );
}
