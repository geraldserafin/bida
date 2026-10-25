import { Effect } from "effect";
import { SqlClient } from "effect/sql";

// Spaces, categories and periods give way to envelopes that belong to people
// (docs/ENVELOPE_MODEL.md). The data of every space goes to the user who owns
// it: a category becomes a top-level envelope (with the same id), the income
// of a period an income, and what a period planned for a category an
// allocation, both dated at the start of the period. A space nobody belongs to
// (the default one, never claimed) has no owner to give its data to, so it is
// dropped with the rest.
export default Effect.gen(function* () {
  const sql = yield* SqlClient.SqlClient;

  yield* sql`
    CREATE TEMP TABLE space_owner AS
      SELECT DISTINCT ON (space_id) space_id, user_id
      FROM memberships
      ORDER BY space_id, (role = 'owner') DESC, created_at, user_id
  `;

  // the old per-period envelopes make room for the new ones
  yield* sql`ALTER TABLE envelopes RENAME TO period_envelopes`;
  yield* sql`ALTER TABLE period_envelopes RENAME CONSTRAINT envelopes_pkey TO period_envelopes_pkey`;

  yield* sql`
    CREATE TABLE envelopes (
      id         uuid        PRIMARY KEY,
      owner_id   uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
      parent_id  uuid        REFERENCES envelopes (id) ON DELETE CASCADE,
      name       text        NOT NULL,
      color      text        NOT NULL,
      icon       text,
      created_at timestamptz NOT NULL,
      updated_at timestamptz NOT NULL,
      CHECK (parent_id IS NULL OR parent_id <> id)
    )
  `;
  yield* sql`CREATE INDEX envelopes_owner_idx ON envelopes (owner_id)`;
  yield* sql`CREATE INDEX envelopes_parent_idx ON envelopes (parent_id)`;

  // who may see a top-level envelope (its sub-envelopes follow it)
  yield* sql`
    CREATE TABLE envelope_members (
      envelope_id uuid        NOT NULL REFERENCES envelopes (id) ON DELETE CASCADE,
      user_id     uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
      role        text        NOT NULL CHECK (role IN ('owner', 'member')),
      created_at  timestamptz NOT NULL DEFAULT now(),
      PRIMARY KEY (envelope_id, user_id)
    )
  `;
  yield* sql`CREATE INDEX envelope_members_user_idx ON envelope_members (user_id)`;

  yield* sql`
    CREATE TABLE incomes (
      id           uuid        PRIMARY KEY,
      user_id      uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
      amount_minor bigint      NOT NULL CHECK (amount_minor > 0),
      received_on  date        NOT NULL,
      note         text,
      created_at   timestamptz NOT NULL,
      updated_at   timestamptz NOT NULL
    )
  `;
  yield* sql`CREATE INDEX incomes_user_idx ON incomes (user_id, received_on)`;

  yield* sql`
    CREATE TABLE allocations (
      id           uuid        PRIMARY KEY,
      envelope_id  uuid        NOT NULL REFERENCES envelopes (id) ON DELETE CASCADE,
      user_id      uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
      amount_minor bigint      NOT NULL CHECK (amount_minor <> 0),
      made_on      date        NOT NULL,
      note         text,
      created_at   timestamptz NOT NULL,
      updated_at   timestamptz NOT NULL
    )
  `;
  yield* sql`CREATE INDEX allocations_envelope_idx ON allocations (envelope_id, made_on)`;
  yield* sql`CREATE INDEX allocations_user_idx ON allocations (user_id, made_on)`;

  // ---- move the data ------------------------------------------------------
  yield* sql`
    INSERT INTO envelopes (id, owner_id, parent_id, name, color, icon, created_at, updated_at)
    SELECT c.id, o.user_id, NULL, c.name, c.color, c.icon, c.created_at, c.updated_at
    FROM categories c JOIN space_owner o ON o.space_id = c.space_id
  `;
  yield* sql`
    INSERT INTO envelope_members (envelope_id, user_id, role)
    SELECT id, owner_id, 'owner' FROM envelopes
  `;
  yield* sql`
    INSERT INTO incomes (id, user_id, amount_minor, received_on, note, created_at, updated_at)
    SELECT gen_random_uuid(), o.user_id, p.income_minor, p.start_date, p.name, now(), now()
    FROM periods p JOIN space_owner o ON o.space_id = p.space_id
    WHERE p.income_minor > 0
  `;
  yield* sql`
    INSERT INTO allocations (id, envelope_id, user_id, amount_minor, made_on, note, created_at, updated_at)
    SELECT gen_random_uuid(), pe.category_id, o.user_id, pe.planned_minor, p.start_date, p.name, now(), now()
    FROM period_envelopes pe
    JOIN periods p ON p.id = pe.period_id
    JOIN space_owner o ON o.space_id = p.space_id
    WHERE pe.planned_minor > 0
  `;

  // ---- expenses: now on an envelope, with an author ------------------------
  // dropping period_id also drops the foreign key (envelope, period) and the
  // indexes that used it
  yield* sql`
    ALTER TABLE expenses
      DROP COLUMN period_id CASCADE,
      DROP COLUMN original_amount_minor,
      DROP COLUMN original_currency,
      ADD COLUMN created_by uuid REFERENCES users (id),
      ADD COLUMN recurring_month date
  `;
  yield* sql`
    UPDATE expenses x
    SET created_by = o.user_id,
        envelope_id = pe.category_id,
        recurring_month = CASE WHEN x.recurring_id IS NULL THEN NULL
          ELSE date_trunc('month', x.spent_at AT TIME ZONE 'Europe/Warsaw')::date END
    FROM period_envelopes pe, space_owner o
    WHERE pe.id = x.envelope_id AND o.space_id = x.space_id
  `;
  yield* sql`DELETE FROM expenses WHERE created_by IS NULL`;
  // a rule applied in two periods of one month would break the unique index
  yield* sql`
    UPDATE expenses SET recurring_month = NULL
    WHERE id IN (
      SELECT id FROM (
        SELECT id, row_number() OVER (
          PARTITION BY recurring_id, recurring_month ORDER BY spent_at, id
        ) AS n
        FROM expenses WHERE recurring_month IS NOT NULL
      ) numbered WHERE n > 1
    )
  `;
  yield* sql`ALTER TABLE expenses ALTER COLUMN created_by SET NOT NULL`;
  yield* sql`ALTER TABLE expenses DROP COLUMN space_id`;
  yield* sql`
    ALTER TABLE expenses
      ADD CONSTRAINT expenses_envelope_fkey
        FOREIGN KEY (envelope_id) REFERENCES envelopes (id) ON DELETE CASCADE
  `;
  yield* sql`CREATE INDEX expenses_envelope_spent_idx ON expenses (envelope_id, spent_at DESC)`;
  yield* sql`CREATE INDEX expenses_author_spent_idx ON expenses (created_by, spent_at DESC)`;
  // a rule produces at most one expense per month, even under concurrent applies
  yield* sql`
    CREATE UNIQUE INDEX expenses_recurring_month_key
      ON expenses (recurring_id, recurring_month)
      WHERE recurring_id IS NOT NULL AND recurring_month IS NOT NULL
  `;

  // ---- recurring rules: now on an envelope, owned by a user ----------------
  yield* sql`
    ALTER TABLE recurring_rules
      DROP COLUMN currency,
      ADD COLUMN user_id uuid REFERENCES users (id) ON DELETE CASCADE
  `;
  yield* sql`
    UPDATE recurring_rules r SET user_id = o.user_id
    FROM space_owner o WHERE o.space_id = r.space_id
  `;
  yield* sql`DELETE FROM recurring_rules WHERE user_id IS NULL`;
  yield* sql`ALTER TABLE recurring_rules ALTER COLUMN user_id SET NOT NULL`;
  yield* sql`ALTER TABLE recurring_rules DROP COLUMN space_id`;
  // the envelope of a category has the id of the category
  yield* sql`ALTER TABLE recurring_rules DROP CONSTRAINT recurring_rules_category_id_fkey`;
  yield* sql`ALTER TABLE recurring_rules RENAME COLUMN category_id TO envelope_id`;
  yield* sql`
    ALTER TABLE recurring_rules
      ADD CONSTRAINT recurring_rules_envelope_fkey
        FOREIGN KEY (envelope_id) REFERENCES envelopes (id) ON DELETE CASCADE
  `;
  yield* sql`CREATE INDEX recurring_rules_user_idx ON recurring_rules (user_id)`;

  // ---- what is no longer needed ---------------------------------------------
  yield* sql`DROP TABLE period_envelopes`;
  yield* sql`DROP TABLE periods`;
  yield* sql`DROP TABLE categories`;
  yield* sql`DROP TABLE memberships`;
  yield* sql`DROP TABLE spaces`;
  yield* sql`DROP TABLE space_owner`;
});
