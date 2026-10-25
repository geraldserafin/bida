import { Effect } from "effect";
import { SqlClient } from "effect/sql";

export default Effect.gen(function* () {
  const sql = yield* SqlClient.SqlClient;
  yield* sql`
    CREATE TABLE periods (
      id           uuid        PRIMARY KEY,
      name         text        NOT NULL,
      start_date   date        NOT NULL,
      end_date     date        NOT NULL,
      income_minor bigint      NOT NULL CHECK (income_minor >= 0),
      created_at   timestamptz NOT NULL,
      updated_at   timestamptz NOT NULL,
      CHECK (end_date >= start_date)
    )
  `;
  yield* sql`
    CREATE TABLE envelopes (
      id            uuid        PRIMARY KEY,
      period_id     uuid        NOT NULL REFERENCES periods (id) ON DELETE CASCADE,
      category_id   uuid        NOT NULL REFERENCES categories (id) ON DELETE RESTRICT,
      planned_minor bigint      NOT NULL CHECK (planned_minor >= 0),
      created_at    timestamptz NOT NULL,
      updated_at    timestamptz NOT NULL,
      UNIQUE (period_id, category_id)
    )
  `;
});
