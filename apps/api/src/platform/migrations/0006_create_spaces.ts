import { Effect } from "effect";
import { SqlClient } from "effect/sql";

// Same as DEFAULT_SPACE_ID in the contract
const DEFAULT_SPACE = "00000000-0000-4000-8000-000000000001";
const TABLES = [
  "categories",
  "periods",
  "envelopes",
  "expenses",
  "recurring_rules",
];

export default Effect.gen(function* () {
  const sql = yield* SqlClient.SqlClient;
  yield* sql`
    CREATE TABLE spaces (
      id               uuid        PRIMARY KEY,
      name             text        NOT NULL,
      default_currency text        NOT NULL CHECK (default_currency ~ '^[A-Z]{3}$'),
      created_at       timestamptz NOT NULL,
      updated_at       timestamptz NOT NULL
    )
  `;
  yield* sql`
    INSERT INTO spaces (id, name, default_currency, created_at, updated_at)
    VALUES (${DEFAULT_SPACE}, 'Default', 'PLN', now(), now())
  `;
  // Existing rows go to the default space; after that every insert has to say
  // which space it is for.
  for (const table of TABLES) {
    yield* sql.unsafe(
      `ALTER TABLE ${table}
         ADD COLUMN space_id uuid NOT NULL DEFAULT '${DEFAULT_SPACE}'
           REFERENCES spaces (id) ON DELETE CASCADE`,
    );
    yield* sql.unsafe(
      `ALTER TABLE ${table} ALTER COLUMN space_id DROP DEFAULT`,
    );
    yield* sql.unsafe(`CREATE INDEX ${table}_space_idx ON ${table} (space_id)`);
  }
});
