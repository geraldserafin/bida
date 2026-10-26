import { Effect } from "effect";
import { SqlClient } from "effect/sql";

// Rules that put money in on their own: an income that repeats (a salary) and
// a sum that goes into an envelope every month.
export default Effect.gen(function* () {
  const sql = yield* SqlClient.SqlClient;

  yield* sql`
    CREATE TABLE recurring_incomes (
      id           uuid        PRIMARY KEY,
      user_id      uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
      amount_minor bigint      NOT NULL CHECK (amount_minor > 0),
      day_of_month integer     NOT NULL CHECK (day_of_month BETWEEN 1 AND 28),
      note         text,
      active       boolean     NOT NULL,
      created_at   timestamptz NOT NULL,
      updated_at   timestamptz NOT NULL
    )
  `;
  yield* sql`CREATE INDEX recurring_incomes_user_idx ON recurring_incomes (user_id)`;

  yield* sql`
    CREATE TABLE allocation_rules (
      id           uuid        PRIMARY KEY,
      user_id      uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
      envelope_id  uuid        NOT NULL REFERENCES envelopes (id) ON DELETE CASCADE,
      amount_minor bigint      NOT NULL CHECK (amount_minor > 0),
      day_of_month integer     NOT NULL CHECK (day_of_month BETWEEN 1 AND 28),
      note         text,
      active       boolean     NOT NULL,
      created_at   timestamptz NOT NULL,
      updated_at   timestamptz NOT NULL
    )
  `;
  yield* sql`CREATE INDEX allocation_rules_user_idx ON allocation_rules (user_id)`;
  yield* sql`CREATE INDEX allocation_rules_envelope_idx ON allocation_rules (envelope_id)`;

  // Deleting a rule keeps what it made. A rule makes at most one entry per
  // stretch, even under concurrent applies.
  yield* sql`
    ALTER TABLE incomes
      ADD COLUMN recurring_id uuid REFERENCES recurring_incomes (id) ON DELETE SET NULL,
      ADD COLUMN recurring_month date
  `;
  yield* sql`
    CREATE UNIQUE INDEX incomes_recurring_month_key
      ON incomes (recurring_id, recurring_month)
      WHERE recurring_id IS NOT NULL AND recurring_month IS NOT NULL
  `;
  yield* sql`
    ALTER TABLE allocations
      ADD COLUMN rule_id uuid REFERENCES allocation_rules (id) ON DELETE SET NULL,
      ADD COLUMN rule_month date
  `;
  yield* sql`
    CREATE UNIQUE INDEX allocations_rule_month_key
      ON allocations (rule_id, rule_month)
      WHERE rule_id IS NOT NULL AND rule_month IS NOT NULL
  `;
});
