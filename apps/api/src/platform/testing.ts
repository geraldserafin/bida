import {
  CurrentSpace,
  DEFAULT_SPACE_ID,
  Space,
  SpaceContext,
} from "@bida/api-contract";
import { DateTime, Effect, Layer } from "effect";
import { SqlClient } from "effect/sql";

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
  yield* sql`DELETE FROM spaces WHERE id <> ${DEFAULT_SPACE_ID}`;
});

const epoch = DateTime.makeUnsafe(0);

/** The default space, as the middleware would provide it for a request. */
export const defaultSpace = new Space({
  id: DEFAULT_SPACE_ID,
  name: "Default",
  defaultCurrency: "PLN",
  createdAt: epoch,
  updatedAt: epoch,
});

/** Runs services as a request in the given space (the default one if omitted). */
export const TestSpace = (space: Space = defaultSpace) =>
  Layer.succeed(CurrentSpace, space);

/** A `SpaceContext` middleware that always puts requests in the given space. */
export const TestSpaceContext = (space: Space = defaultSpace) =>
  Layer.succeed(
    SpaceContext,
    SpaceContext.of((httpEffect) =>
      Effect.provideService(httpEffect, CurrentSpace, space),
    ),
  );
