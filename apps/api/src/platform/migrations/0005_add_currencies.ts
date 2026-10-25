import { Effect } from "effect";
import { SqlClient } from "effect/sql";

// The set of valid codes lives in the contract (the Currency enum), so the
// database only checks the shape and adding a currency needs no migration.
export default Effect.gen(function* () {
  const sql = yield* SqlClient.SqlClient;
  yield* sql`
    ALTER TABLE periods
      ADD COLUMN currency text NOT NULL DEFAULT 'PLN' CHECK (currency ~ '^[A-Z]{3}$')
  `;
  yield* sql`
    ALTER TABLE recurring_rules
      ADD COLUMN currency text NOT NULL DEFAULT 'PLN' CHECK (currency ~ '^[A-Z]{3}$')
  `;
  // What was actually paid, when it was in another currency than the period's
  yield* sql`
    ALTER TABLE expenses
      ADD COLUMN original_amount_minor bigint CHECK (original_amount_minor > 0),
      ADD COLUMN original_currency text CHECK (original_currency ~ '^[A-Z]{3}$'),
      ADD CONSTRAINT expenses_original_both_or_none
        CHECK ((original_amount_minor IS NULL) = (original_currency IS NULL))
  `;
});
