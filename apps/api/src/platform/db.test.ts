import { assert, layer } from "@effect/vitest";
import { Effect } from "effect";
import { SqlClient } from "effect/sql";
import { DbLive } from "./db.ts";

layer(DbLive)("DbLive", (it) => {
  it.effect("connects and has run the migrator", () =>
    Effect.gen(function* () {
      const sql = yield* SqlClient.SqlClient;
      assert.deepStrictEqual(yield* sql`SELECT 1 AS ok`, [{ ok: 1 }]);
      assert.deepStrictEqual(
        yield* sql`SELECT to_regclass('effect_sql_migrations') IS NOT NULL AS applied`,
        [{ applied: true }],
      );
    }),
  );
});
