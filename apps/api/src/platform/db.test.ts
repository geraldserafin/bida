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

  it.effect("has the tables of the v0.5 money model", () =>
    Effect.gen(function* () {
      const sql = yield* SqlClient.SqlClient;
      const rows = yield* sql<{ tablename: string }>`
        SELECT tablename FROM pg_tables
        WHERE schemaname = 'public' AND tablename NOT LIKE 'effect_sql%'
        ORDER BY tablename
      `;
      assert.deepStrictEqual(
        rows.map((r) => r.tablename),
        [
          "change_log",
          "envelopes",
          "expenses",
          "household_members",
          "households",
          "identities",
          "invitations",
          "login_codes",
          "period_moves",
          "period_summary_seen",
          "periods",
          "plans",
          "recurring_rules",
          "rule_occurrences",
          "sessions",
          "todo_items",
          "users",
          "wallet_entries",
        ],
      );
    }),
  );
});
