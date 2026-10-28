import { Effect } from "effect";
import { SqlClient } from "effect/sql";

// Every recurring expense is monthly. A weekly rule was applied once a month
// already, so making it monthly changes nothing it does.
export default Effect.gen(function* () {
  const sql = yield* SqlClient.SqlClient;

  yield* sql`UPDATE recurring_rules SET frequency = 'monthly' WHERE frequency = 'weekly'`;
  yield* sql`ALTER TABLE recurring_rules DROP CONSTRAINT recurring_rules_frequency_check`;
  yield* sql`
    ALTER TABLE recurring_rules
      ADD CONSTRAINT recurring_rules_frequency_check CHECK (frequency = 'monthly')
  `;
});
