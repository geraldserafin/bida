import { Effect } from "effect";
import { SqlClient } from "effect/sql";

export default Effect.gen(function* () {
  const sql = yield* SqlClient.SqlClient;
  // How a user proved who they are besides the e-mail link: the id the
  // provider (e.g. Google) gives them stays the same when the address changes.
  yield* sql`
    CREATE TABLE identities (
      provider   text        NOT NULL,
      subject    text        NOT NULL,
      user_id    uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
      created_at timestamptz NOT NULL DEFAULT now(),
      PRIMARY KEY (provider, subject)
    )
  `;
  yield* sql`CREATE INDEX identities_user_idx ON identities (user_id)`;
});
