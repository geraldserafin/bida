import { generateKeyPairSync, sign } from "node:crypto";
import { InvalidLogin } from "@bida/api-contract";
import { assert, it } from "@effect/vitest";
import { Effect } from "effect";
import { type GoogleKey, GoogleVerifier } from "./google.ts";

const CLIENT = "web-client.apps.googleusercontent.com";
const NOW = Date.UTC(2026, 9, 25, 12, 0, 0);

const keyPair = () => {
  const { publicKey, privateKey } = generateKeyPairSync("rsa", {
    modulusLength: 2048,
  });
  return { publicKey, privateKey };
};
const good = keyPair();
const other = keyPair();
const jwk = (kid: string, key = good.publicKey): GoogleKey => ({
  kid,
  ...key.export({ format: "jwk" }),
});

const b64 = (value: unknown) =>
  Buffer.from(JSON.stringify(value)).toString("base64url");

/** An ID token as Google would issue it, with room to break each part. */
const token = (
  claims: Record<string, unknown> = {},
  options: { alg?: string; kid?: string; key?: typeof good.privateKey } = {},
) => {
  const header = b64({ alg: options.alg ?? "RS256", kid: options.kid ?? "k1" });
  const payload = b64({
    iss: "https://accounts.google.com",
    aud: CLIENT,
    sub: "1234",
    exp: NOW / 1000 + 600,
    email: "ann@example.com",
    email_verified: true,
    name: "Ann",
    ...claims,
  });
  const signature = sign(
    "RSA-SHA256",
    Buffer.from(`${header}.${payload}`),
    options.key ?? good.privateKey,
  ).toString("base64url");
  return `${header}.${payload}.${signature}`;
};

let fetches = 0;
const loadKeys = Effect.sync(() => {
  fetches++;
  return { keys: [jwk("k1")], ttlSeconds: 3600 };
});

/** What Google's token endpoints answer, by URL; anything else fails. */
let answers: Record<string, unknown> = {};
const getJson = (url: string) =>
  Object.entries(answers).find(([prefix]) => url.startsWith(prefix))?.[1] ===
  undefined
    ? Effect.fail("no answer")
    : Effect.succeed(
        Object.entries(answers).find(([prefix]) => url.startsWith(prefix))?.[1],
      );

const verifier = (clients = [CLIENT]) =>
  Effect.service(GoogleVerifier).pipe(
    Effect.provide(
      GoogleVerifier.layerWith({
        loadKeys,
        getJson,
        clientIds: clients,
        now: () => NOW,
      }),
    ),
  );

const refused = (idToken: string, clients?: string[]) =>
  Effect.gen(function* () {
    const google = yield* verifier(clients);
    const error = yield* google.verify(idToken).pipe(Effect.flip);
    assert.instanceOf(error, InvalidLogin);
  });

it.effect("accepts a token signed by Google for this app", () =>
  Effect.gen(function* () {
    const google = yield* verifier();
    const profile = yield* google.verify(token());
    assert.deepStrictEqual(profile, {
      subject: "1234",
      email: "ann@example.com",
      name: "Ann",
    });
  }),
);

it.effect("accepts the other issuer spelling and a string email_verified", () =>
  Effect.gen(function* () {
    const google = yield* verifier();
    yield* google.verify(
      token({ iss: "accounts.google.com", email_verified: "true" }),
    );
  }),
);

it.effect("refuses a token for another app", () =>
  refused(token({ aud: "x" })),
);
it.effect("refuses any token when no client id is set", () =>
  refused(token(), []),
);
it.effect("refuses an expired token", () =>
  refused(token({ exp: NOW / 1000 - 1 })),
);
it.effect("refuses another issuer", () =>
  refused(token({ iss: "https://evil.example" })),
);
it.effect("refuses an address Google did not verify", () =>
  refused(token({ email_verified: false })),
);
it.effect("refuses a signature from another key", () =>
  refused(token({}, { key: other.privateKey })),
);
it.effect("refuses an algorithm other than RS256", () =>
  Effect.all([
    refused(token({}, { alg: "none" })),
    refused(token({}, { alg: "HS256" })),
  ]),
);
it.effect("refuses a key id Google does not publish", () =>
  refused(token({}, { kid: "unknown" })),
);
it.effect("refuses things that are not tokens", () =>
  Effect.all([
    refused(""),
    refused("a.b"),
    refused("a.b.c"),
    refused("a.b.c.d"),
  ]),
);
it.effect("refuses a payload that was changed after signing", () =>
  Effect.gen(function* () {
    const [header, , signature] = token().split(".");
    const forged = b64({
      iss: "https://accounts.google.com",
      aud: CLIENT,
      sub: "999",
      exp: NOW / 1000 + 600,
      email: "victim@example.com",
      email_verified: true,
    });
    yield* refused(`${header}.${forged}.${signature}`);
  }),
);

it.effect("keeps Google's keys instead of asking for every token", () =>
  Effect.gen(function* () {
    fetches = 0;
    const google = yield* verifier();
    yield* google.verify(token());
    yield* google.verify(token());
    yield* google.verify(token());
    assert.strictEqual(fetches, 1);
  }),
);

// ------------------------------------------------------------- access tokens

const TOKENINFO = "https://oauth2.googleapis.com/tokeninfo";
const USERINFO = "https://openidconnect.googleapis.com/v1/userinfo";

/** What Google's tokeninfo says about an access token. */
const info = (changes: Record<string, unknown> = {}) => ({
  aud: CLIENT,
  sub: "1234",
  email: "ann@example.com",
  email_verified: "true",
  expires_in: "3000",
  ...changes,
});

const refusedAccessToken = (
  tokeninfo: Record<string, unknown> | undefined,
  clients?: string[],
) =>
  Effect.gen(function* () {
    answers = tokeninfo === undefined ? {} : { [TOKENINFO]: tokeninfo };
    const google = yield* verifier(clients);
    const error = yield* google
      .verifyAccessToken("access-token-from-the-browser")
      .pipe(Effect.flip);
    assert.instanceOf(error, InvalidLogin);
  });

it.effect("accepts an access token issued to this app", () =>
  Effect.gen(function* () {
    answers = { [TOKENINFO]: info(), [USERINFO]: { name: " Ann " } };
    const google = yield* verifier();
    const profile = yield* google.verifyAccessToken("access-token");
    assert.deepStrictEqual(profile, {
      subject: "1234",
      email: "ann@example.com",
      name: "Ann",
    });
  }),
);

it.effect("signs in without a name when Google does not give one", () =>
  Effect.gen(function* () {
    answers = { [TOKENINFO]: info() };
    const google = yield* verifier();
    const profile = yield* google.verifyAccessToken("access-token");
    assert.strictEqual(profile.name, null);
  }),
);

it.effect("refuses an access token issued to another app", () =>
  refusedAccessToken(info({ aud: "someone-elses.apps.googleusercontent.com" })),
);
it.effect("refuses any access token when no client id is set", () =>
  refusedAccessToken(info(), []),
);
it.effect("refuses an access token for an address Google did not verify", () =>
  refusedAccessToken(info({ email_verified: "false" })),
);
it.effect("refuses an expired access token", () =>
  refusedAccessToken(info({ expires_in: "0" })),
);
it.effect("refuses an access token without a subject", () =>
  refusedAccessToken(info({ sub: "" })),
);
it.effect("refuses an access token Google does not know", () =>
  refusedAccessToken(undefined),
);
it.effect("refuses a tokeninfo answer of the wrong shape", () =>
  refusedAccessToken({ error: "invalid_token" }),
);
