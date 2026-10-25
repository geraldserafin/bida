import { Effect } from "effect";
import { SqlClient } from "effect/sql";

export default Effect.gen(function* () {
  const sql = yield* SqlClient.SqlClient;
  // Money paid into the budget of a period, next to the income that was
  // planned. It stays when the person who paid leaves or their account goes.
  yield* sql`
    CREATE TABLE contributions (
      id             uuid        PRIMARY KEY,
      space_id       uuid        NOT NULL REFERENCES spaces (id) ON DELETE CASCADE,
      period_id      uuid        NOT NULL REFERENCES periods (id) ON DELETE CASCADE,
      user_id        uuid        REFERENCES users (id) ON DELETE SET NULL,
      amount_minor   bigint      NOT NULL CHECK (amount_minor > 0),
      contributed_at timestamptz NOT NULL,
      note           text,
      created_at     timestamptz NOT NULL
    )
  `;
  yield* sql`CREATE INDEX contributions_period_idx ON contributions (period_id, contributed_at DESC)`;
});
