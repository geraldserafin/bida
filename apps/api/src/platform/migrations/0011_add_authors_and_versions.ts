import { Effect } from "effect";
import { SqlClient } from "effect/sql";

export default Effect.gen(function* () {
  const sql = yield* SqlClient.SqlClient;
  // Who added the expense. It stays when the person leaves the space, and
  // goes empty only when their account is deleted.
  yield* sql`
    ALTER TABLE expenses
      ADD COLUMN created_by uuid REFERENCES users (id) ON DELETE SET NULL
  `;
  // Counts the plan edits of a period, so an edit made on stale data is refused
  // instead of overwriting what somebody else changed in the meantime.
  yield* sql`ALTER TABLE periods ADD COLUMN version integer NOT NULL DEFAULT 1`;
});
