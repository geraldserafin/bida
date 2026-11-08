import { Effect } from "effect";
import { SqlClient } from "effect/sql";

// A transfer rule can follow an income rule: each time an occurrence of the
// income is certain (made with a known amount, or its estimate confirmed),
// the whole amount goes on into the household. Such a rule has no schedule
// of its own; it goes when its income goes.
export default Effect.gen(function* () {
  const sql = yield* SqlClient.SqlClient;
  yield* sql`
    ALTER TABLE recurring_rules
      ADD COLUMN income_rule_id uuid REFERENCES recurring_rules (id) ON DELETE CASCADE,
      ADD CHECK (income_rule_id IS NULL OR kind = 'transfer')
  `;
  yield* sql`CREATE INDEX recurring_rules_income_idx ON recurring_rules (income_rule_id)`;
});
