import {
  InvalidLogin,
  TooManyRequests,
  Unauthorized,
} from "@bida/api-contract";
import { assert, layer } from "@effect/vitest";
import { Effect, Layer } from "effect";
import { SqlClient } from "effect/sql";
import { DbLive } from "../../platform/db.ts";
import { outbox, resetDb, TestMailer } from "../../platform/testing.ts";
import { AuthModule, AuthService, GoogleVerifier } from "./auth.module.ts";

/** Google tokens are `subject|email|name` here; the real check has its own test. */
const TestGoogle = Layer.succeed(
  GoogleVerifier,
  GoogleVerifier.of({
    verify: (idToken) => {
      const [subject, email, name] = idToken.split("|");
      return subject && email
        ? Effect.succeed({ subject, email, name: name || null })
        : Effect.fail(new InvalidLogin());
    },
    verifyAccessToken: (accessToken) => {
      const [subject, email, name] = accessToken.split("|");
      return subject && email
        ? Effect.succeed({ subject, email, name: name || null })
        : Effect.fail(new InvalidLogin());
    },
  }),
);

const TestLayer = AuthModule.pipe(
  Layer.provideMerge(TestGoogle),
  Layer.provideMerge(TestMailer),
  Layer.provideMerge(DbLive),
);

const lastMail = () => {
  const mail = outbox.at(-1);
  if (mail === undefined) throw new Error("no e-mail was sent");
  return {
    code: /kod logowania: (\d{6})/.exec(mail.text)?.[1] ?? "",
    token: /login_token=(\S+)/.exec(mail.text)?.[1] ?? "",
    to: mail.to,
  };
};

const start = Effect.gen(function* () {
  yield* resetDb;
  outbox.length = 0;
});

layer(TestLayer)("sign-in", (it) => {
  it.effect("a code from the e-mail signs in and creates the account", () =>
    Effect.gen(function* () {
      yield* start;
      const auth = yield* AuthService;

      yield* auth.requestLink("  Ann@Example.com ");
      const mail = lastMail();
      assert.strictEqual(mail.to, "ann@example.com");
      assert.match(mail.code, /^\d{6}$/);

      const signedIn = yield* auth.verifyCode(
        "ann@example.com",
        mail.code,
        "tests",
      );
      assert.strictEqual(signedIn.user.email, "ann@example.com");

      const current = yield* auth.authenticate(signedIn.token);
      assert.strictEqual(current.user.id, signedIn.user.id);

      yield* auth.logout(current.sessionId);
      const error = yield* auth.authenticate(signedIn.token).pipe(Effect.flip);
      assert.instanceOf(error, Unauthorized);
    }),
  );

  it.effect("the link token signs in too, and only once", () =>
    Effect.gen(function* () {
      yield* start;
      const auth = yield* AuthService;
      yield* auth.requestLink("bob@example.com");
      const { token } = lastMail();

      const signedIn = yield* auth.verifyToken(token, null);
      assert.strictEqual(signedIn.user.email, "bob@example.com");
      const again = yield* auth.verifyToken(token, null).pipe(Effect.flip);
      assert.instanceOf(again, InvalidLogin);
    }),
  );

  it.effect("a code works once, and not for another address", () =>
    Effect.gen(function* () {
      yield* start;
      const auth = yield* AuthService;
      yield* auth.requestLink("cat@example.com");
      const { code } = lastMail();

      const other = yield* auth
        .verifyCode("dan@example.com", code, null)
        .pipe(Effect.flip);
      assert.instanceOf(other, InvalidLogin);

      yield* auth.verifyCode("cat@example.com", code, null);
      const again = yield* auth
        .verifyCode("cat@example.com", code, null)
        .pipe(Effect.flip);
      assert.instanceOf(again, InvalidLogin);
    }),
  );

  it.effect("five wrong tries lock the code, even for the right one", () =>
    Effect.gen(function* () {
      yield* start;
      const auth = yield* AuthService;
      yield* auth.requestLink("eve@example.com");
      const { code } = lastMail();
      const wrong = code === "000000" ? "000001" : "000000";

      for (let i = 0; i < 5; i++) {
        const error = yield* auth
          .verifyCode("eve@example.com", wrong, null)
          .pipe(Effect.flip);
        assert.instanceOf(error, InvalidLogin);
      }
      const locked = yield* auth
        .verifyCode("eve@example.com", code, null)
        .pipe(Effect.flip);
      assert.instanceOf(locked, InvalidLogin);
    }),
  );

  it.effect("an expired code and link are refused", () =>
    Effect.gen(function* () {
      yield* start;
      const auth = yield* AuthService;
      const sql = yield* SqlClient.SqlClient;
      yield* auth.requestLink("fay@example.com");
      const { code, token } = lastMail();
      yield* sql`UPDATE login_codes SET expires_at = now() - interval '1 second'`;

      assert.instanceOf(
        yield* auth.verifyCode("fay@example.com", code, null).pipe(Effect.flip),
        InvalidLogin,
      );
      assert.instanceOf(
        yield* auth.verifyToken(token, null).pipe(Effect.flip),
        InvalidLogin,
      );
    }),
  );

  it.effect("an address can only ask for five e-mails an hour", () =>
    Effect.gen(function* () {
      yield* start;
      const auth = yield* AuthService;
      for (let i = 0; i < 5; i++) yield* auth.requestLink("gus@example.com");
      const error = yield* auth
        .requestLink("gus@example.com")
        .pipe(Effect.flip);
      assert.instanceOf(error, TooManyRequests);
      // another address is not affected
      yield* auth.requestLink("hal@example.com");
    }),
  );

  it.effect("signing in again finds the same account", () =>
    Effect.gen(function* () {
      yield* start;
      const auth = yield* AuthService;

      yield* auth.requestLink("ida@example.com");
      const first = yield* auth.verifyCode(
        "ida@example.com",
        lastMail().code,
        null,
      );
      yield* auth.requestLink("ida@example.com");
      const second = yield* auth.verifyCode(
        "ida@example.com",
        lastMail().code,
        null,
      );

      assert.strictEqual(first.user.id, second.user.id);
      assert.notStrictEqual(first.token, second.token);
      // both devices stay signed in
      yield* auth.authenticate(first.token);
      yield* auth.authenticate(second.token);
    }),
  );

  it.effect("a Google account signs in and is found again", () =>
    Effect.gen(function* () {
      yield* start;
      const auth = yield* AuthService;

      const first = yield* auth.signInWithGoogle(
        "g1|Gus@Example.com|Gus",
        null,
      );
      assert.strictEqual(first.user.email, "gus@example.com");
      assert.strictEqual(first.user.name, "Gus");
      assert.strictEqual(
        (yield* auth.authenticate(first.token)).user.id,
        first.user.id,
      );

      const again = yield* auth.signInWithGoogle(
        "g1|gus@example.com|Gus",
        null,
      );
      assert.strictEqual(again.user.id, first.user.id);
    }),
  );

  it.effect("Google and the e-mail link reach the same account", () =>
    Effect.gen(function* () {
      yield* start;
      const auth = yield* AuthService;

      yield* auth.requestLink("hal@example.com");
      const byMail = yield* auth.verifyCode(
        "hal@example.com",
        lastMail().code,
        null,
      );
      const byGoogle = yield* auth.signInWithGoogle(
        "g2|hal@example.com|Hal",
        null,
      );

      assert.strictEqual(byGoogle.user.id, byMail.user.id);
    }),
  );

  it.effect("a Google account keeps its user when the address changes", () =>
    Effect.gen(function* () {
      yield* start;
      const auth = yield* AuthService;

      const before = yield* auth.signInWithGoogle(
        "g3|old@example.com|Ivy",
        null,
      );
      const after = yield* auth.signInWithGoogle(
        "g3|new@example.com|Ivy",
        null,
      );

      assert.strictEqual(after.user.id, before.user.id);
      assert.strictEqual(after.user.email, "old@example.com");
    }),
  );

  it.effect("an access token from a browser signs in the same way", () =>
    Effect.gen(function* () {
      yield* start;
      const auth = yield* AuthService;

      yield* auth.requestLink("jo@example.com");
      const byMail = yield* auth.verifyCode(
        "jo@example.com",
        lastMail().code,
        null,
      );
      const byBrowser = yield* auth.signInWithGoogleAccessToken(
        "g9|jo@example.com|Jo",
        null,
      );

      assert.strictEqual(byBrowser.user.id, byMail.user.id);
      const refused = yield* auth
        .signInWithGoogleAccessToken("nonsense", null)
        .pipe(Effect.flip);
      assert.instanceOf(refused, InvalidLogin);
    }),
  );

  it.effect("a token Google would not vouch for is refused", () =>
    Effect.gen(function* () {
      const auth = yield* AuthService;
      const error = yield* auth
        .signInWithGoogle("nonsense", null)
        .pipe(Effect.flip);
      assert.instanceOf(error, InvalidLogin);
    }),
  );

  it.effect("unknown and empty tokens are not signed in", () =>
    Effect.gen(function* () {
      const auth = yield* AuthService;
      for (const token of ["", "nope", "x".repeat(500)]) {
        assert.instanceOf(
          yield* auth.authenticate(token).pipe(Effect.flip),
          Unauthorized,
        );
      }
    }),
  );
});
