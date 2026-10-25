import { Effect } from "effect";
import { SqlClient } from "effect/sql";

export default Effect.gen(function* () {
  const sql = yield* SqlClient.SqlClient;
  yield* sql`
    CREATE TABLE recurring_rules (
      id           uuid        PRIMARY KEY,
      category_id  uuid        NOT NULL REFERENCES categories (id) ON DELETE CASCADE,
      amount_minor bigint      NOT NULL CHECK (amount_minor > 0),
      frequency    text        NOT NULL CHECK (frequency IN ('weekly', 'monthly')),
      note         text,
      active       boolean     NOT NULL,
      created_at   timestamptz NOT NULL,
      updated_at   timestamptz NOT NULL
    )
  `;
  // Deleting a rule keeps the expenses it generated.
  yield* sql`
    ALTER TABLE expenses
      ADD COLUMN recurring_id uuid REFERENCES recurring_rules (id) ON DELETE SET NULL
  `;
  // A rule produces at most one expense per period, even under concurrent applies.
  yield* sql`
    CREATE UNIQUE INDEX expenses_period_recurring_key
      ON expenses (period_id, recurring_id) WHERE recurring_id IS NOT NULL
  `;
});
