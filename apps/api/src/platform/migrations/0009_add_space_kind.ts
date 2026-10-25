import { Effect } from "effect";
import { SqlClient } from "effect/sql";

// Same as DEFAULT_SPACE_ID in the contract
const DEFAULT_SPACE = "00000000-0000-4000-8000-000000000001";

export default Effect.gen(function* () {
  const sql = yield* SqlClient.SqlClient;
  yield* sql`
    ALTER TABLE spaces
      ADD COLUMN kind text NOT NULL DEFAULT 'shared'
        CHECK (kind IN ('personal', 'shared')),
      -- the user a personal space belongs to; at most one each
      ADD COLUMN personal_for uuid UNIQUE REFERENCES users (id) ON DELETE CASCADE
  `;
  // The first space of every user becomes their personal one, any later ones
  // stay shared (they could only have been made through the API).
  yield* sql`
    WITH first_space AS (
      SELECT DISTINCT ON (m.user_id) m.user_id, m.space_id
      FROM memberships m
      ORDER BY m.user_id, m.created_at, m.space_id
    )
    UPDATE spaces s
    SET kind = 'personal', personal_for = f.user_id
    FROM first_space f
    WHERE s.id = f.space_id
  `;
  // Data from before accounts is somebody's personal budget once it is claimed
  yield* sql`UPDATE spaces SET kind = 'personal' WHERE id = ${DEFAULT_SPACE}`;
  yield* sql`ALTER TABLE spaces ALTER COLUMN kind DROP DEFAULT`;
});
