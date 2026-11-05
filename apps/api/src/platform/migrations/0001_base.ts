import { Effect } from "effect";
import { SqlClient } from "effect/sql";

// The money model of SWS v0.5 (docs/MONEY_MODEL.md): a private wallet per
// account, households with periods, every period a piggy bank with plans for
// its envelopes. It starts from an empty database; nothing is carried over
// from the envelope model before it.
export default Effect.gen(function* () {
  const sql = yield* SqlClient.SqlClient;

  // ---- accounts ---------------------------------------------------------------
  yield* sql`
    CREATE TABLE users (
      id         uuid        PRIMARY KEY,
      email      text        NOT NULL UNIQUE CHECK (email = lower(email)),
      name       text,
      created_at timestamptz NOT NULL
    )
  `;
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

  // ---- households -------------------------------------------------------------
  // The cycle of periods: monthly from a day (29-31 fall on the last day of a
  // shorter month), every N weeks from an anchor day, or manual (a new period
  // is as long as the one before; the owner moves its end).
  yield* sql`
    CREATE TABLE households (
      id           uuid        PRIMARY KEY,
      name         text        NOT NULL,
      time_zone    text        NOT NULL DEFAULT 'Europe/Warsaw',
      cycle_kind   text        NOT NULL CHECK (cycle_kind IN ('monthly', 'weeks', 'manual')),
      cycle_day    integer     CHECK (cycle_day BETWEEN 1 AND 31),
      cycle_weeks  integer     CHECK (cycle_weeks BETWEEN 1 AND 52),
      cycle_anchor date,
      created_at   timestamptz NOT NULL,
      updated_at   timestamptz NOT NULL,
      CHECK (cycle_kind <> 'monthly' OR cycle_day IS NOT NULL),
      CHECK (cycle_kind <> 'weeks' OR (cycle_weeks IS NOT NULL AND cycle_anchor IS NOT NULL))
    )
  `;
  // A frozen member cannot spend; they are removed once their share is no
  // longer negative.
  yield* sql`
    CREATE TABLE household_members (
      household_id uuid        NOT NULL REFERENCES households (id) ON DELETE CASCADE,
      user_id      uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
      role         text        NOT NULL CHECK (role IN ('owner', 'member')),
      frozen_at    timestamptz,
      joined_at    timestamptz NOT NULL DEFAULT now(),
      PRIMARY KEY (household_id, user_id)
    )
  `;
  yield* sql`CREATE INDEX household_members_user_idx ON household_members (user_id)`;
  // An invitation is for an e-mail address: whoever signs in with it sees it,
  // and accepting it makes them a member.
  yield* sql`
    CREATE TABLE invitations (
      id           uuid        PRIMARY KEY,
      household_id uuid        NOT NULL REFERENCES households (id) ON DELETE CASCADE,
      email        text        NOT NULL CHECK (email = lower(email)),
      role         text        NOT NULL CHECK (role IN ('owner', 'member')),
      status       text        NOT NULL CHECK (status IN ('invited', 'accepted', 'declined', 'revoked')),
      invited_by   uuid        REFERENCES users (id) ON DELETE SET NULL,
      accepted_by  uuid        REFERENCES users (id) ON DELETE SET NULL,
      created_at   timestamptz NOT NULL DEFAULT now(),
      updated_at   timestamptz NOT NULL DEFAULT now(),
      expires_at   timestamptz NOT NULL
    )
  `;
  yield* sql`
    CREATE UNIQUE INDEX invitations_open_idx ON invitations (household_id, email)
    WHERE status = 'invited'
  `;
  yield* sql`CREATE INDEX invitations_email_idx ON invitations (email)`;
  yield* sql`CREATE INDEX invitations_sender_idx ON invitations (invited_by, created_at)`;

  // ---- periods: one piggy bank each --------------------------------------------
  // Both days are included, in the time zone of the household. At most two are
  // open (closed_at IS NULL): the current one and the next one.
  yield* sql`
    CREATE TABLE periods (
      id              uuid        PRIMARY KEY,
      household_id    uuid        NOT NULL REFERENCES households (id) ON DELETE CASCADE,
      starts_on       date        NOT NULL,
      ends_on         date        NOT NULL,
      closed_at       timestamptz,
      -- what went on to the next period when it was closed
      carry_out_minor bigint,
      created_at      timestamptz NOT NULL,
      CHECK (ends_on >= starts_on),
      UNIQUE (household_id, starts_on)
    )
  `;
  yield* sql`CREATE INDEX periods_open_idx ON periods (household_id) WHERE closed_at IS NULL`;
  yield* sql`
    CREATE TABLE period_summary_seen (
      period_id uuid NOT NULL REFERENCES periods (id) ON DELETE CASCADE,
      user_id   uuid NOT NULL REFERENCES users (id) ON DELETE CASCADE,
      seen_at   timestamptz NOT NULL DEFAULT now(),
      PRIMARY KEY (period_id, user_id)
    )
  `;

  // ---- envelopes and their plans ----------------------------------------------
  yield* sql`
    CREATE TABLE envelopes (
      id           uuid        PRIMARY KEY,
      household_id uuid        NOT NULL REFERENCES households (id) ON DELETE CASCADE,
      name         text        NOT NULL,
      color        text        NOT NULL,
      icon         text,
      position     integer     NOT NULL DEFAULT 0,
      archived_at  timestamptz,
      created_at   timestamptz NOT NULL,
      updated_at   timestamptz NOT NULL
    )
  `;
  yield* sql`CREATE UNIQUE INDEX envelopes_name_key ON envelopes (household_id, lower(name))`;
  // The plan the user sees is manual + recurring. The recurring part is the
  // expense rules of the envelope times their occurrences in the period, kept
  // apart so that nothing is counted twice; the manual part can be negative
  // when somebody plans less than the rules add up to.
  yield* sql`
    CREATE TABLE plans (
      period_id       uuid   NOT NULL REFERENCES periods (id) ON DELETE CASCADE,
      envelope_id     uuid   NOT NULL REFERENCES envelopes (id) ON DELETE CASCADE,
      manual_minor    bigint NOT NULL DEFAULT 0,
      recurring_minor bigint NOT NULL DEFAULT 0 CHECK (recurring_minor >= 0),
      PRIMARY KEY (period_id, envelope_id),
      CHECK (manual_minor + recurring_minor >= 0)
    )
  `;

  // ---- recurring rules ----------------------------------------------------------
  // income: into the wallet of user_id. transfer: from that wallet into a
  // period of household_id (target: the period of the day, or the next one).
  // expense: of household_id, on envelope_id, written by user_id (who made
  // the rule). An estimated income or expense goes in with its estimate and
  // waits for the real amount in the to-do list.
  yield* sql`
    CREATE TABLE recurring_rules (
      id           uuid        PRIMARY KEY,
      kind         text        NOT NULL CHECK (kind IN ('income', 'transfer', 'expense')),
      user_id      uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
      household_id uuid        REFERENCES households (id) ON DELETE CASCADE,
      envelope_id  uuid        REFERENCES envelopes (id) ON DELETE CASCADE,
      name         text        NOT NULL,
      amount_minor bigint      NOT NULL CHECK (amount_minor > 0),
      estimated    boolean     NOT NULL DEFAULT false,
      frequency    text        NOT NULL CHECK (frequency IN ('monthly', 'weeks')),
      day_of_month integer     CHECK (day_of_month BETWEEN 1 AND 31),
      every_weeks  integer     CHECK (every_weeks BETWEEN 1 AND 52),
      anchor_on    date,
      starts_on    date        NOT NULL,
      target       text        CHECK (target IN ('current', 'next')),
      active       boolean     NOT NULL DEFAULT true,
      created_at   timestamptz NOT NULL,
      updated_at   timestamptz NOT NULL,
      CHECK (frequency <> 'monthly' OR day_of_month IS NOT NULL),
      CHECK (frequency <> 'weeks' OR (every_weeks IS NOT NULL AND anchor_on IS NOT NULL)),
      CHECK (kind = 'income' OR household_id IS NOT NULL),
      CHECK (kind <> 'transfer' OR target IS NOT NULL),
      CHECK (kind <> 'expense' OR envelope_id IS NOT NULL)
    )
  `;
  yield* sql`CREATE INDEX recurring_rules_user_idx ON recurring_rules (user_id)`;
  yield* sql`CREATE INDEX recurring_rules_household_idx ON recurring_rules (household_id)`;
  // Every occurrence a rule has been dealt with, whatever came of it (done,
  // waiting in the to-do list, missed): opening the app again does nothing
  // twice.
  yield* sql`
    CREATE TABLE rule_occurrences (
      rule_id       uuid        NOT NULL REFERENCES recurring_rules (id) ON DELETE CASCADE,
      occurrence_on date        NOT NULL,
      outcome       text        NOT NULL CHECK (outcome IN ('done', 'todo', 'missed')),
      created_at    timestamptz NOT NULL DEFAULT now(),
      PRIMARY KEY (rule_id, occurrence_on)
    )
  `;

  // ---- money in a period ----------------------------------------------------------
  // transfer: from the wallet of user_id in; withdrawal: back to it; carry:
  // what was left of the period before, nobody's (user_id NULL); forfeit: a
  // share given up (somebody left), moves from user_id to nobody and does not
  // change the balance.
  yield* sql`
    CREATE TABLE period_moves (
      id            uuid        PRIMARY KEY,
      period_id     uuid        NOT NULL REFERENCES periods (id) ON DELETE CASCADE,
      household_id  uuid        NOT NULL REFERENCES households (id) ON DELETE CASCADE,
      user_id       uuid        REFERENCES users (id) ON DELETE SET NULL,
      user_name     text,
      kind          text        NOT NULL CHECK (kind IN ('transfer', 'withdrawal', 'carry', 'forfeit')),
      amount_minor  bigint      NOT NULL CHECK (amount_minor > 0),
      made_at       timestamptz NOT NULL,
      rule_id       uuid        REFERENCES recurring_rules (id) ON DELETE SET NULL,
      occurrence_on date,
      created_at    timestamptz NOT NULL,
      CHECK (kind <> 'carry' OR user_id IS NULL)
    )
  `;
  yield* sql`CREATE INDEX period_moves_period_idx ON period_moves (period_id)`;
  yield* sql`CREATE INDEX period_moves_user_idx ON period_moves (user_id)`;
  yield* sql`
    CREATE UNIQUE INDEX period_moves_rule_key ON period_moves (rule_id, occurrence_on)
    WHERE rule_id IS NOT NULL
  `;

  // The author and "for whom" keep their names after they leave. An envelope
  // with expenses is archived, not deleted; the cascade is for a household
  // that goes with everything in it.
  yield* sql`
    CREATE TABLE expenses (
      id               uuid        PRIMARY KEY,
      period_id        uuid        NOT NULL REFERENCES periods (id) ON DELETE CASCADE,
      household_id     uuid        NOT NULL REFERENCES households (id) ON DELETE CASCADE,
      envelope_id      uuid        NOT NULL REFERENCES envelopes (id) ON DELETE CASCADE,
      created_by       uuid        REFERENCES users (id) ON DELETE SET NULL,
      author_name      text        NOT NULL,
      amount_minor     bigint      NOT NULL CHECK (amount_minor > 0),
      spent_at         timestamptz NOT NULL,
      title            text,
      for_whom         text        CHECK (for_whom IN ('member', 'shared')),
      for_whom_user_id uuid        REFERENCES users (id) ON DELETE SET NULL,
      for_whom_name    text,
      estimated        boolean     NOT NULL DEFAULT false,
      rule_id          uuid        REFERENCES recurring_rules (id) ON DELETE SET NULL,
      occurrence_on    date,
      created_at       timestamptz NOT NULL,
      updated_at       timestamptz NOT NULL,
      CHECK (for_whom = 'member' OR for_whom_user_id IS NULL)
    )
  `;
  yield* sql`CREATE INDEX expenses_period_idx ON expenses (period_id, spent_at)`;
  yield* sql`CREATE INDEX expenses_household_spent_idx ON expenses (household_id, spent_at DESC)`;
  yield* sql`CREATE INDEX expenses_envelope_idx ON expenses (envelope_id)`;
  yield* sql`
    CREATE UNIQUE INDEX expenses_rule_key ON expenses (rule_id, occurrence_on)
    WHERE rule_id IS NOT NULL
  `;

  // ---- the wallet -------------------------------------------------------------------
  // income: in (pewny or szacowany); transfer: out to a household; withdrawal:
  // back from one; return: a share that came back when a household was
  // deleted or the user was removed from it. The rows stay when the household
  // goes, so the wallet keeps its balance; the name is kept for the history.
  yield* sql`
    CREATE TABLE wallet_entries (
      id             uuid        PRIMARY KEY,
      user_id        uuid        NOT NULL REFERENCES users (id) ON DELETE CASCADE,
      kind           text        NOT NULL CHECK (kind IN ('income', 'transfer', 'withdrawal', 'return')),
      amount_minor   bigint      NOT NULL CHECK (amount_minor > 0),
      on_date        date        NOT NULL,
      note           text,
      estimated      boolean     NOT NULL DEFAULT false,
      rule_id        uuid        REFERENCES recurring_rules (id) ON DELETE SET NULL,
      occurrence_on  date,
      move_id        uuid        REFERENCES period_moves (id) ON DELETE SET NULL,
      household_id   uuid        REFERENCES households (id) ON DELETE SET NULL,
      household_name text,
      created_at     timestamptz NOT NULL,
      updated_at     timestamptz NOT NULL,
      CHECK (kind = 'income' OR NOT estimated)
    )
  `;
  yield* sql`CREATE INDEX wallet_entries_user_idx ON wallet_entries (user_id, on_date DESC)`;
  yield* sql`CREATE INDEX wallet_entries_move_idx ON wallet_entries (move_id)`;
  yield* sql`
    CREATE UNIQUE INDEX wallet_entries_rule_key ON wallet_entries (rule_id, occurrence_on)
    WHERE rule_id IS NOT NULL AND kind = 'income'
  `;

  // ---- the to-do list -------------------------------------------------------------------
  // Matters that need somebody to decide. Those of a wallet (user_id) are seen
  // by its owner, those of a household (household_id) by all its members;
  // done by one, gone for everybody.
  yield* sql`
    CREATE TABLE todo_items (
      id            uuid        PRIMARY KEY,
      kind          text        NOT NULL CHECK (kind IN (
                      'income_estimate', 'transfer_no_money', 'expense_not_fit',
                      'expense_estimate', 'expense_missed')),
      user_id       uuid        REFERENCES users (id) ON DELETE CASCADE,
      household_id  uuid        REFERENCES households (id) ON DELETE CASCADE,
      period_id     uuid        REFERENCES periods (id) ON DELETE CASCADE,
      rule_id       uuid        REFERENCES recurring_rules (id) ON DELETE CASCADE,
      occurrence_on date,
      ref_id        uuid,
      amount_minor  bigint      NOT NULL CHECK (amount_minor > 0),
      title         text,
      created_at    timestamptz NOT NULL,
      resolved_at   timestamptz,
      resolved_by   uuid        REFERENCES users (id) ON DELETE SET NULL,
      CHECK ((user_id IS NULL) <> (household_id IS NULL))
    )
  `;
  yield* sql`CREATE INDEX todo_items_user_idx ON todo_items (user_id) WHERE resolved_at IS NULL`;
  yield* sql`CREATE INDEX todo_items_household_idx ON todo_items (household_id) WHERE resolved_at IS NULL`;
  yield* sql`CREATE UNIQUE INDEX todo_items_ref_key ON todo_items (kind, ref_id) WHERE ref_id IS NOT NULL`;
  yield* sql`
    CREATE UNIQUE INDEX todo_items_rule_key ON todo_items (kind, rule_id, occurrence_on)
    WHERE rule_id IS NOT NULL
  `;

  // ---- the change log ---------------------------------------------------------------------
  // Only for the open periods: the entries of a period go when it is closed.
  // before/after hold what an undo needs.
  yield* sql`
    CREATE TABLE change_log (
      id           uuid        PRIMARY KEY,
      household_id uuid        NOT NULL REFERENCES households (id) ON DELETE CASCADE,
      period_id    uuid        NOT NULL REFERENCES periods (id) ON DELETE CASCADE,
      user_id      uuid        REFERENCES users (id) ON DELETE SET NULL,
      user_name    text        NOT NULL,
      action       text        NOT NULL,
      entity_id    uuid        NOT NULL,
      summary      text        NOT NULL,
      before       jsonb,
      after        jsonb,
      created_at   timestamptz NOT NULL,
      undone_at    timestamptz,
      undone_by    uuid        REFERENCES users (id) ON DELETE SET NULL
    )
  `;
  yield* sql`CREATE INDEX change_log_household_idx ON change_log (household_id, created_at DESC)`;
});
