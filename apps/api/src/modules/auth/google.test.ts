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

const verifier = (clients = [CLIENT]) =>
  Effect.service(GoogleVerifier).pipe(
    Effect.provide(GoogleVerifier.layerWith(loadKeys, clients, () => NOW)),
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
