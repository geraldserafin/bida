import { Effect } from "effect";
import { SqlClient } from "effect/sql";

/** Empties every application table of the test database, keeps the schema. */
export const resetDb = Effect.gen(function* () {
  const sql = yield* SqlClient.SqlClient;
  const tables = yield* sql<{ tablename: string }>`
    SELECT tablename FROM pg_tables
    WHERE schemaname = 'public' AND tablename NOT LIKE 'effect_sql%'
  `;
  if (tables.length === 0) return;
  const names = tables.map((t) => `"${t.tablename}"`).join(", ");
  yield* sql.unsafe(`TRUNCATE ${names} CASCADE`);
});
