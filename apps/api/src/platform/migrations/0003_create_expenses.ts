import { Effect } from "effect";
import { SqlClient } from "effect/sql";

export default Effect.gen(function* () {
  const sql = yield* SqlClient.SqlClient;
  // Lets an expense point at (envelope, period) so both stay consistent.
  yield* sql`
    ALTER TABLE envelopes
      ADD CONSTRAINT envelopes_id_period_id_key UNIQUE (id, period_id)
  `;
  // Deleting a period removes its expenses through period_id. Deleting a
  // single envelope that still has expenses fails: the envelope reference is
  // NO ACTION, which is only checked once the whole statement (including the
  // cascades) is done.
  yield* sql`
    CREATE TABLE expenses (
      id           uuid        PRIMARY KEY,
      period_id    uuid        NOT NULL REFERENCES periods (id) ON DELETE CASCADE,
      envelope_id  uuid        NOT NULL,
      amount_minor bigint      NOT NULL CHECK (amount_minor > 0),
      spent_at     timestamptz NOT NULL,
      note         text,
      created_at   timestamptz NOT NULL,
      updated_at   timestamptz NOT NULL,
      FOREIGN KEY (envelope_id, period_id) REFERENCES envelopes (id, period_id)
    )
  `;
  yield* sql`CREATE INDEX expenses_period_spent_at_idx ON expenses (period_id, spent_at DESC)`;
  yield* sql`CREATE INDEX expenses_envelope_idx ON expenses (envelope_id)`;
});
