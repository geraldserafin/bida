import { Effect } from "effect";
import { SqlClient } from "effect/sql";

export default Effect.gen(function* () {
  const sql = yield* SqlClient.SqlClient;
  yield* sql`
    CREATE TABLE categories (
      id         uuid        PRIMARY KEY,
      name       text        NOT NULL,
      color      text        NOT NULL,
      icon       text,
      created_at timestamptz NOT NULL,
      updated_at timestamptz NOT NULL
    )
  `;
});
