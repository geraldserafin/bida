import { Effect } from "effect";
import { SqlClient } from "effect/sql";

export default Effect.gen(function* () {
  const sql = yield* SqlClient.SqlClient;
  yield* sql`
    CREATE TABLE users (
      id         uuid        PRIMARY KEY,
      email      text        NOT NULL UNIQUE CHECK (email = lower(email)),
      name       text,
      created_at timestamptz NOT NULL
    )
  `;
  // Who works in which space. Everything else in a space is reached through
  // this table.
  yield* sql`
    CREATE TABLE memberships (
      space_id   uuid        NOT NULL REFERENCES spaces (id) ON DELETE CASCADE,
      user_id    uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
      role       text        NOT NULL CHECK (role IN ('owner', 'member')),
      created_at timestamptz NOT NULL DEFAULT now(),
      PRIMARY KEY (space_id, user_id)
    )
  `;
  yield* sql`CREATE INDEX memberships_user_idx ON memberships (user_id)`;
  // One row per e-mail sent. The link token and the code are only stored
  // hashed, and each can be used once.
  yield* sql`
    CREATE TABLE login_codes (
      id         uuid        PRIMARY KEY,
      email      text        NOT NULL,
      token_hash text        NOT NULL UNIQUE,
      code_hash  text        NOT NULL,
      attempts   integer     NOT NULL DEFAULT 0,
      expires_at timestamptz NOT NULL,
      used_at    timestamptz,
      created_at timestamptz NOT NULL DEFAULT now()
    )
  `;
  yield* sql`CREATE INDEX login_codes_email_idx ON login_codes (email, created_at)`;
  // A signed-in device. The token is only stored hashed; deleting the row
  // ends the session at once.
  yield* sql`
    CREATE TABLE sessions (
      id           uuid        PRIMARY KEY,
      user_id      uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
      token_hash   text        NOT NULL UNIQUE,
      user_agent   text,
      created_at   timestamptz NOT NULL DEFAULT now(),
      last_used_at timestamptz NOT NULL DEFAULT now(),
      expires_at   timestamptz NOT NULL
    )
  `;
  yield* sql`CREATE INDEX sessions_user_idx ON sessions (user_id)`;
});
