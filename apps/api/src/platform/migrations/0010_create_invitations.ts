import { Effect } from "effect";
import { SqlClient } from "effect/sql";

export default Effect.gen(function* () {
  const sql = yield* SqlClient.SqlClient;
  // An invitation is for an e-mail address, not a link: whoever signs in with
  // the address sees it. The last states are kept for the record.
  yield* sql`
    CREATE TABLE invitations (
      id          uuid        PRIMARY KEY,
      envelope_id uuid        NOT NULL REFERENCES envelopes (id) ON DELETE CASCADE,
      email       text        NOT NULL CHECK (email = lower(email)),
      role        text        NOT NULL CHECK (role IN ('owner', 'member')),
      status      text        NOT NULL CHECK (status IN
                    ('invited', 'accepted', 'approved', 'declined', 'rejected', 'revoked')),
      invited_by  uuid        REFERENCES users (id) ON DELETE SET NULL,
      accepted_by uuid        REFERENCES users (id) ON DELETE SET NULL,
      created_at  timestamptz NOT NULL DEFAULT now(),
      updated_at  timestamptz NOT NULL DEFAULT now(),
      expires_at  timestamptz NOT NULL
    )
  `;
  // one open invitation per address and envelope
  yield* sql`
    CREATE UNIQUE INDEX invitations_open_idx ON invitations (envelope_id, email)
    WHERE status IN ('invited', 'accepted')
  `;
  yield* sql`CREATE INDEX invitations_email_idx ON invitations (email)`;
  yield* sql`CREATE INDEX invitations_sender_idx ON invitations (invited_by, created_at)`;
});
