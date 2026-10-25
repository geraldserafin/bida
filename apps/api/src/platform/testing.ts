import {
  Authenticated,
  CurrentMember,
  CurrentSpace,
  CurrentUser,
  DEFAULT_SPACE_ID,
  type Role,
  Space,
  SpaceContext,
  User,
  UserId,
} from "@bida/api-contract";
import { DateTime, Effect, Layer } from "effect";
import { SqlClient } from "effect/sql";
import { type Mail, Mailer } from "./mailer.ts";

/**
 * Empties every application table of the test database and keeps the schema
 * and the default space. Other spaces are removed with everything in them.
 */
export const resetDb = Effect.gen(function* () {
  const sql = yield* SqlClient.SqlClient;
  const tables = yield* sql<{ tablename: string }>`
    SELECT tablename FROM pg_tables
    WHERE schemaname = 'public'
      AND tablename NOT LIKE 'effect_sql%'
      AND tablename <> 'spaces'
  `;
  if (tables.length > 0) {
    const names = tables.map((t) => `"${t.tablename}"`).join(", ");
    yield* sql.unsafe(`TRUNCATE ${names} CASCADE`);
  }
  // truncating users takes the spaces with it (they point at their user), and
  // the default space has to stay
  yield* sql`
    INSERT INTO spaces (id, name, default_currency, kind, created_at, updated_at)
    VALUES (${DEFAULT_SPACE_ID}, 'Default', 'PLN', 'personal', now(), now())
    ON CONFLICT (id) DO NOTHING`;
  yield* sql`DELETE FROM spaces WHERE id <> ${DEFAULT_SPACE_ID}`;
});

const epoch = DateTime.makeUnsafe(0);

/** The default space, as the middleware would provide it for a request. */
export const defaultSpace = new Space({
  id: DEFAULT_SPACE_ID,
  name: "Default",
  defaultCurrency: "PLN",
  kind: "personal",
  createdAt: epoch,
  updatedAt: epoch,
});

/** Runs services as a request in the given space (the default one if omitted). */
export const TestSpace = (space: Space = defaultSpace) =>
  Layer.succeed(CurrentSpace, space);

/** A `SpaceContext` middleware that always puts requests in the given space. */
export const TestSpaceContext = (
  space: Space = defaultSpace,
  role: Role = "owner",
) =>
  Layer.succeed(
    SpaceContext,
    SpaceContext.of((httpEffect) =>
      httpEffect.pipe(
        Effect.provideService(CurrentSpace, space),
        Effect.provideService(CurrentMember, {
          userId: "00000000-0000-4000-8000-0000000000aa",
          role,
        }),
      ),
    ),
  );

const user = new User({
  id: UserId.make("00000000-0000-4000-8000-0000000000aa"),
  email: "tester@example.com",
  name: null,
  createdAt: epoch,
});

/** The user that `TestAuthenticated` signs every request in as. */
export const testUser = user;

/** An `Authenticated` middleware that signs every request in as `testUser`. */
export const TestAuthenticated = (signedIn: User = testUser) => {
  const current = { user: signedIn, sessionId: "test-session" };
  return Layer.succeed(
    Authenticated,
    Authenticated.of({
      bearer: (httpEffect) =>
        Effect.provideService(httpEffect, CurrentUser, current),
      cookie: (httpEffect) =>
        Effect.provideService(httpEffect, CurrentUser, current),
    }),
  );
};

/** A user row, so a space can have somebody to belong to. */
export const insertUser = Effect.fn("insertUser")(function* (
  email = `${crypto.randomUUID()}@example.com`,
) {
  const sql = yield* SqlClient.SqlClient;
  const id = crypto.randomUUID();
  yield* sql`INSERT INTO users (id, email, created_at) VALUES (${id}, ${email}, now())`;
  return { id, email };
});

/** E-mails sent through `TestMailer`, oldest first. Empty it between tests. */
export const outbox: Array<Mail> = [];

/** A `Mailer` that keeps the e-mails in `outbox` instead of sending them. */
export const TestMailer = Layer.succeed(
  Mailer,
  Mailer.of({
    send: (mail) =>
      Effect.sync(() => {
        outbox.push(mail);
      }),
  }),
);
