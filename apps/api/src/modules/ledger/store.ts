import { Effect } from "effect";
import { SqlClient } from "effect/sql";
import type { Day } from "./dates.ts";

// SQL only: no business rules. Every function needs `SqlClient`; failures of
// the database are defects. bigint comes back from pg as a string and `date`
// as a Date, so both are cast in the queries.

const run = <A extends object>(
  query: (sql: SqlClient.SqlClient) => Effect.Effect<ReadonlyArray<A>, unknown>,
) =>
  Effect.gen(function* () {
    const sql = yield* SqlClient.SqlClient;
    return yield* query(sql);
  }).pipe(Effect.orDie);

const first = <A>(rows: ReadonlyArray<A>) => rows[0];

// ---- rows ----------------------------------------------------------------------------

export interface UserRow {
  readonly id: string;
  readonly email: string;
  readonly name: string | null;
}

export interface HouseholdRow {
  readonly id: string;
  readonly name: string;
  readonly timeZone: string;
  readonly cycleKind: "monthly" | "weeks" | "manual";
  readonly cycleDay: number | null;
  readonly cycleWeeks: number | null;
  readonly cycleAnchor: Day | null;
  readonly createdAt: Date;
}

export interface MemberRow {
  readonly householdId: string;
  readonly userId: string;
  readonly email: string;
  readonly name: string | null;
  readonly role: "owner" | "member";
  readonly frozenAt: Date | null;
  readonly joinedAt: Date;
}

export interface PeriodRow {
  readonly id: string;
  readonly householdId: string;
  readonly startsOn: Day;
  readonly endsOn: Day;
  readonly closedAt: Date | null;
  readonly carryOutMinor: number | null;
}

export interface EnvelopeRow {
  readonly id: string;
  readonly householdId: string;
  readonly name: string;
  readonly color: string;
  readonly icon: string | null;
  readonly position: number;
  readonly archivedAt: Date | null;
}

export interface PlanRow {
  readonly periodId: string;
  readonly envelopeId: string;
  readonly manualMinor: number;
  readonly recurringMinor: number;
}

export type MoveKind = "transfer" | "withdrawal" | "carry" | "forfeit";

export interface MoveRow {
  readonly id: string;
  readonly periodId: string;
  readonly householdId: string;
  readonly userId: string | null;
  readonly userName: string | null;
  readonly kind: MoveKind;
  readonly amountMinor: number;
  readonly madeAt: Date;
  readonly ruleId: string | null;
  readonly occurrenceOn: Day | null;
}

export interface ExpenseRow {
  readonly id: string;
  readonly periodId: string;
  readonly householdId: string;
  readonly envelopeId: string;
  readonly createdBy: string | null;
  readonly authorName: string;
  readonly amountMinor: number;
  readonly spentAt: Date;
  readonly title: string | null;
  readonly forWhom: "member" | "shared" | null;
  readonly forWhomUserId: string | null;
  readonly forWhomName: string | null;
  readonly estimated: boolean;
  readonly ruleId: string | null;
  readonly occurrenceOn: Day | null;
  readonly createdAt: Date;
  readonly updatedAt: Date;
}

export type WalletKind = "income" | "transfer" | "withdrawal" | "return";

export interface WalletEntryRow {
  readonly id: string;
  readonly userId: string;
  readonly kind: WalletKind;
  readonly amountMinor: number;
  readonly onDate: Day;
  readonly note: string | null;
  readonly estimated: boolean;
  readonly ruleId: string | null;
  readonly occurrenceOn: Day | null;
  readonly moveId: string | null;
  readonly householdId: string | null;
  readonly householdName: string | null;
  readonly createdAt: Date;
}

export type RuleKind = "income" | "transfer" | "expense";

export interface RuleRow {
  readonly id: string;
  readonly kind: RuleKind;
  readonly userId: string;
  readonly householdId: string | null;
  readonly envelopeId: string | null;
  readonly name: string;
  readonly amountMinor: number;
  readonly estimated: boolean;
  readonly frequency: "monthly" | "weeks";
  readonly dayOfMonth: number | null;
  readonly everyWeeks: number | null;
  readonly anchorOn: Day | null;
  readonly startsOn: Day;
  readonly target: "current" | "next" | null;
  readonly active: boolean;
}

export type TodoKind =
  | "income_estimate"
  | "transfer_no_money"
  | "expense_not_fit"
  | "expense_estimate"
  | "expense_missed";

export interface TodoRow {
  readonly id: string;
  readonly kind: TodoKind;
  readonly userId: string | null;
  readonly householdId: string | null;
  readonly householdName: string | null;
  readonly periodId: string | null;
  readonly ruleId: string | null;
  readonly occurrenceOn: Day | null;
  readonly refId: string | null;
  readonly envelopeId: string | null;
  readonly amountMinor: number;
  readonly title: string | null;
  readonly createdAt: Date;
}

export interface LogRow {
  readonly id: string;
  readonly householdId: string;
  readonly periodId: string;
  readonly userId: string | null;
  readonly userName: string;
  readonly action: string;
  readonly entityId: string;
  readonly summary: string;
  readonly before: unknown;
  readonly after: unknown;
  readonly createdAt: Date;
  readonly undoneAt: Date | null;
}

// ---- users ------------------------------------------------------------------------------

export const userById = (id: string) =>
  run(
    (sql) => sql<UserRow>`SELECT id, email, name FROM users WHERE id = ${id}`,
  ).pipe(Effect.map(first));

export const setUserName = (id: string, name: string | null) =>
  run(
    (sql) =>
      sql<UserRow & { createdAt: Date }>`UPDATE users SET name = ${name}
        WHERE id = ${id} RETURNING id, email, name, created_at`,
  ).pipe(Effect.map(first));

export const deleteUser = (id: string) =>
  run((sql) => sql`DELETE FROM users WHERE id = ${id}`).pipe(Effect.asVoid);

// ---- households and members ---------------------------------------------------------------

const householdColumns = (sql: SqlClient.SqlClient) =>
  sql`h.id, h.name, h.time_zone, h.cycle_kind, h.cycle_day, h.cycle_weeks,
    h.cycle_anchor::text AS cycle_anchor, h.created_at`;

export const householdById = (id: string) =>
  run(
    (sql) =>
      sql<HouseholdRow>`SELECT ${householdColumns(sql)} FROM households h WHERE h.id = ${id}`,
  ).pipe(Effect.map(first));

export const householdsOf = (userId: string) =>
  run(
    (sql) =>
      sql<HouseholdRow>`SELECT ${householdColumns(sql)} FROM households h
        JOIN household_members m ON m.household_id = h.id AND m.user_id = ${userId}
        ORDER BY lower(h.name), h.id`,
  );

export const insertHousehold = (row: {
  id: string;
  name: string;
  timeZone: string;
  cycleKind: string;
  cycleDay: number | null;
  cycleWeeks: number | null;
  cycleAnchor: Day | null;
}) =>
  run(
    (sql) =>
      sql`INSERT INTO households ${sql.insert({ ...row, createdAt: new Date(), updatedAt: new Date() })}`,
  ).pipe(Effect.asVoid);

export const renameHousehold = (id: string, name: string) =>
  run(
    (sql) =>
      sql`UPDATE households SET name = ${name}, updated_at = now() WHERE id = ${id}`,
  ).pipe(Effect.asVoid);

export const setHouseholdCycle = (
  id: string,
  cycle: {
    cycleKind: string;
    cycleDay: number | null;
    cycleWeeks: number | null;
    cycleAnchor: Day | null;
  },
) =>
  run(
    (sql) =>
      sql`UPDATE households SET cycle_kind = ${cycle.cycleKind},
        cycle_day = ${cycle.cycleDay}, cycle_weeks = ${cycle.cycleWeeks},
        cycle_anchor = ${cycle.cycleAnchor}, updated_at = now()
        WHERE id = ${id}`,
  ).pipe(Effect.asVoid);

export const deleteHousehold = (id: string) =>
  run((sql) => sql`DELETE FROM households WHERE id = ${id}`).pipe(
    Effect.asVoid,
  );

const memberColumns = (sql: SqlClient.SqlClient) =>
  sql`m.household_id, m.user_id, u.email, u.name, m.role, m.frozen_at, m.joined_at`;

export const membersOf = (householdId: string) =>
  run(
    (sql) =>
      sql<MemberRow>`SELECT ${memberColumns(sql)} FROM household_members m
        JOIN users u ON u.id = m.user_id
        WHERE m.household_id = ${householdId}
        ORDER BY m.joined_at, m.user_id`,
  );

export const memberOf = (householdId: string, userId: string) =>
  run(
    (sql) =>
      sql<MemberRow>`SELECT ${memberColumns(sql)} FROM household_members m
        JOIN users u ON u.id = m.user_id
        WHERE m.household_id = ${householdId} AND m.user_id = ${userId}`,
  ).pipe(Effect.map(first));

export const insertMember = (
  householdId: string,
  userId: string,
  role: "owner" | "member",
) =>
  run(
    (sql) =>
      sql`INSERT INTO household_members (household_id, user_id, role)
        VALUES (${householdId}, ${userId}, ${role})
        ON CONFLICT DO NOTHING`,
  ).pipe(Effect.asVoid);

export const deleteMember = (householdId: string, userId: string) =>
  run(
    (sql) =>
      sql`DELETE FROM household_members
        WHERE household_id = ${householdId} AND user_id = ${userId}`,
  ).pipe(Effect.asVoid);

export const setRole = (
  householdId: string,
  userId: string,
  role: "owner" | "member",
) =>
  run(
    (sql) =>
      sql`UPDATE household_members SET role = ${role}
        WHERE household_id = ${householdId} AND user_id = ${userId}`,
  ).pipe(Effect.asVoid);

export const setFrozen = (
  householdId: string,
  userId: string,
  frozen: boolean,
) =>
  run(
    (sql) =>
      sql`UPDATE household_members
        SET frozen_at = ${frozen ? new Date() : null}
        WHERE household_id = ${householdId} AND user_id = ${userId}`,
  ).pipe(Effect.asVoid);

// ---- invitations ---------------------------------------------------------------------------

export interface InvitationRow {
  readonly id: string;
  readonly householdId: string;
  readonly householdName: string;
  readonly email: string;
  readonly role: "owner" | "member";
  readonly invitedByEmail: string | null;
  readonly invitedByName: string | null;
  readonly expiresAt: Date;
  readonly createdAt: Date;
}

const invitationSelect = (sql: SqlClient.SqlClient) =>
  sql`SELECT i.id, i.household_id, h.name AS household_name, i.email, i.role,
      u.email AS invited_by_email, u.name AS invited_by_name, i.expires_at, i.created_at
    FROM invitations i
    JOIN households h ON h.id = i.household_id
    LEFT JOIN users u ON u.id = i.invited_by`;

export const openInvitations = (householdId: string) =>
  run(
    (sql) =>
      sql<InvitationRow>`${invitationSelect(sql)}
        WHERE i.household_id = ${householdId} AND i.status = 'invited'
          AND i.expires_at > now()
        ORDER BY i.created_at`,
  );

export const invitationsFor = (email: string) =>
  run(
    (sql) =>
      sql<InvitationRow>`${invitationSelect(sql)}
        WHERE i.email = ${email} AND i.status = 'invited' AND i.expires_at > now()
        ORDER BY i.created_at`,
  );

export const invitationById = (id: string) =>
  run(
    (sql) =>
      sql<InvitationRow>`${invitationSelect(sql)}
        WHERE i.id = ${id} AND i.status = 'invited' AND i.expires_at > now()`,
  ).pipe(Effect.map(first));

export const findOpenInvitation = (householdId: string, email: string) =>
  run(
    (sql) =>
      sql<{ id: string }>`SELECT id FROM invitations
        WHERE household_id = ${householdId} AND email = ${email} AND status = 'invited'`,
  ).pipe(Effect.map(first));

export const insertInvitation = (row: {
  id: string;
  householdId: string;
  email: string;
  role: string;
  invitedBy: string;
  days: number;
}) =>
  run(
    (sql) =>
      sql`INSERT INTO invitations (id, household_id, email, role, status, invited_by, expires_at)
        VALUES (${row.id}, ${row.householdId}, ${row.email}, ${row.role}, 'invited',
          ${row.invitedBy}, now() + make_interval(days => ${row.days}))`,
  ).pipe(Effect.asVoid);

export const renewInvitation = (id: string, role: string, days: number) =>
  run(
    (sql) =>
      sql`UPDATE invitations SET role = ${role}, updated_at = now(),
        expires_at = now() + make_interval(days => ${days})
        WHERE id = ${id}`,
  ).pipe(Effect.asVoid);

export const setInvitationStatus = (
  id: string,
  status: "accepted" | "declined" | "revoked",
  acceptedBy: string | null = null,
) =>
  run(
    (sql) =>
      sql`UPDATE invitations SET status = ${status}, accepted_by = ${acceptedBy},
        updated_at = now() WHERE id = ${id}`,
  ).pipe(Effect.asVoid);

/** Open invitations of a household, the ones that count towards its limit. */
export const countOpenInvitations = (householdId: string) =>
  run(
    (sql) =>
      sql<{ total: number }>`SELECT count(*)::int AS total FROM invitations
        WHERE household_id = ${householdId} AND status = 'invited' AND expires_at > now()`,
  ).pipe(Effect.map((rows) => rows[0]?.total ?? 0));

export const countInvitationsSentSince = (userId: string, seconds: number) =>
  run(
    (sql) =>
      sql<{ total: number }>`SELECT count(*)::int AS total FROM invitations
        WHERE invited_by = ${userId}
          AND created_at > now() - make_interval(secs => ${seconds})`,
  ).pipe(Effect.map((rows) => rows[0]?.total ?? 0));

// ---- periods ------------------------------------------------------------------------------

const periodColumns = (sql: SqlClient.SqlClient) =>
  sql`id, household_id, starts_on::text AS starts_on, ends_on::text AS ends_on,
    closed_at, carry_out_minor::float8 AS carry_out_minor`;

export const periodById = (id: string) =>
  run(
    (sql) =>
      sql<PeriodRow>`SELECT ${periodColumns(sql)} FROM periods WHERE id = ${id}`,
  ).pipe(Effect.map(first));

/** Newest first. */
export const periodsOf = (householdId: string) =>
  run(
    (sql) =>
      sql<PeriodRow>`SELECT ${periodColumns(sql)} FROM periods
        WHERE household_id = ${householdId} ORDER BY starts_on DESC`,
  );

/** The current one first, then the next one. */
export const openPeriodsOf = (householdId: string) =>
  run(
    (sql) =>
      sql<PeriodRow>`SELECT ${periodColumns(sql)} FROM periods
        WHERE household_id = ${householdId} AND closed_at IS NULL
        ORDER BY starts_on`,
  );

export const periodContaining = (householdId: string, day: Day) =>
  run(
    (sql) =>
      sql<PeriodRow>`SELECT ${periodColumns(sql)} FROM periods
        WHERE household_id = ${householdId}
          AND starts_on <= ${day} AND ends_on >= ${day}`,
  ).pipe(Effect.map(first));

export const periodEndingOn = (householdId: string, day: Day) =>
  run(
    (sql) =>
      sql<PeriodRow>`SELECT ${periodColumns(sql)} FROM periods
        WHERE household_id = ${householdId} AND ends_on = ${day}`,
  ).pipe(Effect.map(first));

export const insertPeriod = (row: {
  id: string;
  householdId: string;
  startsOn: Day;
  endsOn: Day;
}) =>
  run(
    (sql) =>
      sql`INSERT INTO periods ${sql.insert({ ...row, createdAt: new Date() })}`,
  ).pipe(Effect.asVoid);

export const setPeriodBounds = (id: string, startsOn: Day, endsOn: Day) =>
  run(
    (sql) =>
      sql`UPDATE periods SET starts_on = ${startsOn}, ends_on = ${endsOn}
        WHERE id = ${id}`,
  ).pipe(Effect.asVoid);

export const closePeriod = (id: string, carryOutMinor: number) =>
  run(
    (sql) =>
      sql`UPDATE periods SET closed_at = now(), carry_out_minor = ${carryOutMinor}
        WHERE id = ${id}`,
  ).pipe(Effect.asVoid);

/** Closed periods of the user's households they have not seen, closed after they joined. */
export const unseenClosed = (userId: string) =>
  run(
    (sql) =>
      sql<PeriodRow & { householdName: string }>`SELECT p.id, p.household_id,
          p.starts_on::text AS starts_on, p.ends_on::text AS ends_on, p.closed_at,
          p.carry_out_minor::float8 AS carry_out_minor, h.name AS household_name
        FROM periods p
        JOIN households h ON h.id = p.household_id
        JOIN household_members m ON m.household_id = p.household_id AND m.user_id = ${userId}
        WHERE p.closed_at IS NOT NULL AND p.closed_at >= m.joined_at
          AND NOT EXISTS (SELECT 1 FROM period_summary_seen s
            WHERE s.period_id = p.id AND s.user_id = ${userId})
        ORDER BY p.ends_on`,
  );

export const markSeen = (periodId: string, userId: string) =>
  run(
    (sql) =>
      sql`INSERT INTO period_summary_seen (period_id, user_id)
        VALUES (${periodId}, ${userId}) ON CONFLICT DO NOTHING`,
  ).pipe(Effect.asVoid);

// ---- envelopes and plans -------------------------------------------------------------------

const envelopeColumns = (sql: SqlClient.SqlClient) =>
  sql`id, household_id, name, color, icon, position, archived_at`;

export const envelopesOf = (householdId: string) =>
  run(
    (sql) =>
      sql<EnvelopeRow>`SELECT ${envelopeColumns(sql)} FROM envelopes
        WHERE household_id = ${householdId}
        ORDER BY archived_at IS NOT NULL, position, lower(name)`,
  );

export const envelopeById = (id: string) =>
  run(
    (sql) =>
      sql<EnvelopeRow>`SELECT ${envelopeColumns(sql)} FROM envelopes WHERE id = ${id}`,
  ).pipe(Effect.map(first));

export const envelopeNamed = (householdId: string, name: string) =>
  run(
    (sql) =>
      sql<EnvelopeRow>`SELECT ${envelopeColumns(sql)} FROM envelopes
        WHERE household_id = ${householdId} AND lower(name) = lower(${name})`,
  ).pipe(Effect.map(first));

export const insertEnvelope = (row: {
  id: string;
  householdId: string;
  name: string;
  color: string;
  icon: string | null;
  position: number;
  archivedAt?: Date | null;
}) =>
  run(
    (sql) =>
      sql`INSERT INTO envelopes ${sql.insert({
        archivedAt: null,
        ...row,
        createdAt: new Date(),
        updatedAt: new Date(),
      })}`,
  ).pipe(Effect.asVoid);

export const updateEnvelope = (
  id: string,
  changes: { name: string; color: string; icon: string | null },
) =>
  run(
    (sql) =>
      sql`UPDATE envelopes SET name = ${changes.name}, color = ${changes.color},
        icon = ${changes.icon}, updated_at = now() WHERE id = ${id}`,
  ).pipe(Effect.asVoid);

export const setArchived = (id: string, archived: boolean) =>
  run(
    (sql) =>
      sql`UPDATE envelopes SET archived_at = ${archived ? new Date() : null},
        updated_at = now() WHERE id = ${id}`,
  ).pipe(Effect.asVoid);

export const deleteEnvelope = (id: string) =>
  run((sql) => sql`DELETE FROM envelopes WHERE id = ${id}`).pipe(Effect.asVoid);

export const envelopeHasExpenses = (id: string) =>
  run(
    (sql) =>
      sql<{
        found: boolean;
      }>`SELECT EXISTS (SELECT 1 FROM expenses WHERE envelope_id = ${id}) AS found`,
  ).pipe(Effect.map((rows) => rows[0]?.found === true));

export const plansOf = (periodId: string) =>
  run(
    (sql) =>
      sql<PlanRow>`SELECT period_id, envelope_id, manual_minor::float8 AS manual_minor,
        recurring_minor::float8 AS recurring_minor
        FROM plans WHERE period_id = ${periodId}`,
  );

export const upsertPlan = (row: PlanRow) =>
  run(
    (sql) =>
      sql`INSERT INTO plans (period_id, envelope_id, manual_minor, recurring_minor)
        VALUES (${row.periodId}, ${row.envelopeId}, ${row.manualMinor}, ${row.recurringMinor})
        ON CONFLICT (period_id, envelope_id) DO UPDATE
          SET manual_minor = EXCLUDED.manual_minor,
              recurring_minor = EXCLUDED.recurring_minor`,
  ).pipe(Effect.asVoid);

// ---- moves ------------------------------------------------------------------------------------

const moveColumns = (sql: SqlClient.SqlClient) =>
  sql`id, period_id, household_id, user_id, user_name, kind,
    amount_minor::float8 AS amount_minor, made_at, rule_id,
    occurrence_on::text AS occurrence_on`;

export const movesOf = (periodId: string) =>
  run(
    (sql) =>
      sql<MoveRow>`SELECT ${moveColumns(sql)} FROM period_moves
        WHERE period_id = ${periodId} ORDER BY made_at DESC, created_at DESC`,
  );

export const moveById = (id: string) =>
  run(
    (sql) =>
      sql<MoveRow>`SELECT ${moveColumns(sql)} FROM period_moves WHERE id = ${id}`,
  ).pipe(Effect.map(first));

export const insertMove = (row: {
  id: string;
  periodId: string;
  householdId: string;
  userId: string | null;
  userName: string | null;
  kind: MoveKind;
  amountMinor: number;
  ruleId?: string | null;
  occurrenceOn?: Day | null;
}) =>
  run(
    (sql) =>
      sql`INSERT INTO period_moves ${sql.insert({
        ruleId: null,
        occurrenceOn: null,
        ...row,
        madeAt: new Date(),
        createdAt: new Date(),
      })}`,
  ).pipe(Effect.asVoid);

export const deleteMove = (id: string) =>
  run((sql) => sql`DELETE FROM period_moves WHERE id = ${id}`).pipe(
    Effect.asVoid,
  );

/** Moves the rows of one period to another (the next period moved with the end). */
export const movesExist = (periodId: string) =>
  run(
    (sql) =>
      sql<{
        found: boolean;
      }>`SELECT EXISTS (SELECT 1 FROM period_moves WHERE period_id = ${periodId}) AS found`,
  ).pipe(Effect.map((rows) => rows[0]?.found === true));

// ---- expenses ------------------------------------------------------------------------------

const expenseColumns = (sql: SqlClient.SqlClient) =>
  sql`x.id, x.period_id, x.household_id, x.envelope_id, x.created_by, x.author_name,
    x.amount_minor::float8 AS amount_minor, x.spent_at, x.title, x.for_whom,
    x.for_whom_user_id, x.for_whom_name, x.estimated, x.rule_id,
    x.occurrence_on::text AS occurrence_on, x.created_at, x.updated_at`;

export const expensesOf = (periodId: string) =>
  run(
    (sql) =>
      sql<ExpenseRow>`SELECT ${expenseColumns(sql)} FROM expenses x
        WHERE x.period_id = ${periodId} ORDER BY x.spent_at, x.created_at`,
  );

export const expenseById = (id: string) =>
  run(
    (sql) =>
      sql<ExpenseRow>`SELECT ${expenseColumns(sql)} FROM expenses x WHERE x.id = ${id}`,
  ).pipe(Effect.map(first));

export type NewExpense = Omit<ExpenseRow, "createdAt" | "updatedAt">;

export const insertExpense = (row: NewExpense) =>
  run(
    (sql) =>
      sql`INSERT INTO expenses ${sql.insert({
        ...row,
        createdAt: new Date(),
        updatedAt: new Date(),
      })}`,
  ).pipe(Effect.asVoid);

export const updateExpense = (
  id: string,
  changes: {
    periodId: string;
    envelopeId: string;
    amountMinor: number;
    spentAt: Date;
    title: string | null;
    forWhom: "member" | "shared" | null;
    forWhomUserId: string | null;
    forWhomName: string | null;
    estimated: boolean;
  },
) =>
  run(
    (sql) =>
      sql`UPDATE expenses SET period_id = ${changes.periodId},
        envelope_id = ${changes.envelopeId}, amount_minor = ${changes.amountMinor},
        spent_at = ${changes.spentAt}, title = ${changes.title},
        for_whom = ${changes.forWhom}, for_whom_user_id = ${changes.forWhomUserId},
        for_whom_name = ${changes.forWhomName}, estimated = ${changes.estimated},
        updated_at = now()
        WHERE id = ${id}`,
  ).pipe(Effect.asVoid);

export const setExpenseTitle = (id: string, title: string | null) =>
  run(
    (sql) =>
      sql`UPDATE expenses SET title = ${title}, updated_at = now() WHERE id = ${id}`,
  ).pipe(Effect.asVoid);

export const deleteExpense = (id: string) =>
  run((sql) => sql`DELETE FROM expenses WHERE id = ${id}`).pipe(Effect.asVoid);

export interface ExpenseFilter {
  readonly householdIds: ReadonlyArray<string>;
  readonly periodId?: string | undefined;
  readonly envelopeId?: string | undefined;
  readonly authorId?: string | undefined;
  /** A member's id, `shared` or `none`. */
  readonly forWhom?: string | undefined;
  readonly from?: Day | undefined;
  readonly to?: Day | undefined;
  readonly limit: number;
  readonly offset: number;
}

export const listExpenses = (filter: ExpenseFilter) =>
  run((sql) => {
    if (filter.householdIds.length === 0)
      return sql<ExpenseRow>`SELECT ${expenseColumns(sql)} FROM expenses x WHERE FALSE`;
    const conditions = [sql.in("x.household_id", filter.householdIds)];
    if (filter.periodId !== undefined)
      conditions.push(sql`x.period_id = ${filter.periodId}`);
    if (filter.envelopeId !== undefined)
      conditions.push(sql`x.envelope_id = ${filter.envelopeId}`);
    if (filter.authorId !== undefined)
      conditions.push(sql`x.created_by = ${filter.authorId}`);
    if (filter.forWhom === "shared")
      conditions.push(sql`x.for_whom = 'shared'`);
    else if (filter.forWhom === "none")
      conditions.push(sql`x.for_whom IS NULL`);
    else if (filter.forWhom !== undefined)
      conditions.push(sql`x.for_whom_user_id = ${filter.forWhom}`);
    if (filter.from !== undefined)
      conditions.push(
        sql`(x.spent_at AT TIME ZONE h.time_zone)::date >= ${filter.from}`,
      );
    if (filter.to !== undefined)
      conditions.push(
        sql`(x.spent_at AT TIME ZONE h.time_zone)::date <= ${filter.to}`,
      );
    return sql<ExpenseRow>`SELECT ${expenseColumns(sql)} FROM expenses x
      JOIN households h ON h.id = x.household_id
      WHERE ${sql.and(conditions)}
      ORDER BY x.spent_at DESC, x.created_at DESC, x.id DESC
      LIMIT ${filter.limit} OFFSET ${filter.offset}`;
  });

export const spentBetween = (householdId: string, from: Day, to: Day) =>
  run(
    (sql) =>
      sql<{
        total: number;
      }>`SELECT COALESCE(SUM(x.amount_minor), 0)::float8 AS total
        FROM expenses x JOIN households h ON h.id = x.household_id
        WHERE x.household_id = ${householdId}
          AND (x.spent_at AT TIME ZONE h.time_zone)::date BETWEEN ${from} AND ${to}`,
  ).pipe(Effect.map((rows) => rows[0]?.total ?? 0));

// ---- the wallet ------------------------------------------------------------------------------

const walletColumns = (sql: SqlClient.SqlClient) =>
  sql`id, user_id, kind, amount_minor::float8 AS amount_minor, on_date::text AS on_date,
    note, estimated, rule_id, occurrence_on::text AS occurrence_on, move_id,
    household_id, household_name, created_at`;

/** wpływy − przelewy + wycofania (+ zwroty), and of it the estimated incomes. */
export const walletOf = (userId: string) =>
  run(
    (sql) =>
      sql<{ balanceMinor: number; unconfirmedMinor: number }>`SELECT
          COALESCE(SUM(CASE WHEN kind = 'transfer' THEN -amount_minor ELSE amount_minor END), 0)::float8
            AS balance_minor,
          COALESCE(SUM(CASE WHEN kind = 'income' AND estimated THEN amount_minor ELSE 0 END), 0)::float8
            AS unconfirmed_minor
        FROM wallet_entries WHERE user_id = ${userId}`,
  ).pipe(
    Effect.map((rows) => rows[0] ?? { balanceMinor: 0, unconfirmedMinor: 0 }),
  );

export const walletEntries = (userId: string, limit: number, offset: number) =>
  run(
    (sql) =>
      sql<WalletEntryRow>`SELECT ${walletColumns(sql)} FROM wallet_entries
        WHERE user_id = ${userId}
        ORDER BY on_date DESC, created_at DESC, id DESC
        LIMIT ${limit} OFFSET ${offset}`,
  );

export const walletEntryById = (id: string) =>
  run(
    (sql) =>
      sql<WalletEntryRow>`SELECT ${walletColumns(sql)} FROM wallet_entries WHERE id = ${id}`,
  ).pipe(Effect.map(first));

export const walletEntryOfMove = (moveId: string) =>
  run(
    (sql) =>
      sql<WalletEntryRow>`SELECT ${walletColumns(sql)} FROM wallet_entries WHERE move_id = ${moveId}`,
  ).pipe(Effect.map(first));

export const insertWalletEntry = (row: {
  id: string;
  userId: string;
  kind: WalletKind;
  amountMinor: number;
  onDate: Day;
  note?: string | null;
  estimated?: boolean;
  ruleId?: string | null;
  occurrenceOn?: Day | null;
  moveId?: string | null;
  householdId?: string | null;
  householdName?: string | null;
}) =>
  run(
    (sql) =>
      sql`INSERT INTO wallet_entries ${sql.insert({
        note: null,
        estimated: false,
        ruleId: null,
        occurrenceOn: null,
        moveId: null,
        householdId: null,
        householdName: null,
        ...row,
        createdAt: new Date(),
        updatedAt: new Date(),
      })}`,
  ).pipe(Effect.asVoid);

export const updateIncome = (
  id: string,
  changes: {
    amountMinor: number;
    onDate: Day;
    note: string | null;
    estimated: boolean;
  },
) =>
  run(
    (sql) =>
      sql`UPDATE wallet_entries SET amount_minor = ${changes.amountMinor},
        on_date = ${changes.onDate}, note = ${changes.note},
        estimated = ${changes.estimated}, updated_at = now()
        WHERE id = ${id}`,
  ).pipe(Effect.asVoid);

export const deleteWalletEntry = (id: string) =>
  run((sql) => sql`DELETE FROM wallet_entries WHERE id = ${id}`).pipe(
    Effect.asVoid,
  );

// ---- recurring rules ---------------------------------------------------------------------------

const ruleColumns = (sql: SqlClient.SqlClient) =>
  sql`r.id, r.kind, r.user_id, r.household_id, r.envelope_id, r.name,
    r.amount_minor::float8 AS amount_minor, r.estimated, r.frequency, r.day_of_month,
    r.every_weeks, r.anchor_on::text AS anchor_on, r.starts_on::text AS starts_on,
    r.target, r.active`;

/** The user's own incomes and transfers, and the expense rules of their households. */
export const rulesVisibleTo = (userId: string) =>
  run(
    (sql) =>
      sql<RuleRow>`SELECT ${ruleColumns(sql)} FROM recurring_rules r
        WHERE (r.kind <> 'expense' AND r.user_id = ${userId})
           OR (r.kind = 'expense' AND r.household_id IN
                (SELECT household_id FROM household_members WHERE user_id = ${userId}))
        ORDER BY r.kind, lower(r.name), r.id`,
  );

export const ruleById = (id: string) =>
  run(
    (sql) =>
      sql<RuleRow>`SELECT ${ruleColumns(sql)} FROM recurring_rules r WHERE r.id = ${id}`,
  ).pipe(Effect.map(first));

export const activeRules = (kind: RuleKind, userId: string) =>
  run(
    (sql) =>
      sql<RuleRow>`SELECT ${ruleColumns(sql)} FROM recurring_rules r
        WHERE r.kind = ${kind} AND r.user_id = ${userId} AND r.active
        ORDER BY r.created_at, r.id`,
  );

export const activeExpenseRulesOf = (householdId: string) =>
  run(
    (sql) =>
      sql<RuleRow>`SELECT ${ruleColumns(sql)} FROM recurring_rules r
        WHERE r.kind = 'expense' AND r.household_id = ${householdId} AND r.active
        ORDER BY r.created_at, r.id`,
  );

export type RuleFields = Omit<RuleRow, "id">;

export const insertRule = (id: string, row: RuleFields) =>
  run(
    (sql) =>
      sql`INSERT INTO recurring_rules ${sql.insert({
        id,
        ...row,
        createdAt: new Date(),
        updatedAt: new Date(),
      })}`,
  ).pipe(Effect.asVoid);

export const updateRule = (id: string, row: RuleFields) =>
  run(
    (sql) =>
      sql`UPDATE recurring_rules SET household_id = ${row.householdId},
        envelope_id = ${row.envelopeId}, name = ${row.name},
        amount_minor = ${row.amountMinor}, estimated = ${row.estimated},
        frequency = ${row.frequency}, day_of_month = ${row.dayOfMonth},
        every_weeks = ${row.everyWeeks}, anchor_on = ${row.anchorOn},
        starts_on = ${row.startsOn}, target = ${row.target}, active = ${row.active},
        updated_at = now()
        WHERE id = ${id}`,
  ).pipe(Effect.asVoid);

export const deactivateRulesOf = (householdId: string, userId: string) =>
  run(
    (sql) =>
      sql`UPDATE recurring_rules SET active = false, updated_at = now()
        WHERE household_id = ${householdId} AND user_id = ${userId}`,
  ).pipe(Effect.asVoid);

export const deleteRule = (id: string) =>
  run((sql) => sql`DELETE FROM recurring_rules WHERE id = ${id}`).pipe(
    Effect.asVoid,
  );

/** The occurrences of a rule that were dealt with, from a day on. */
export const occurrencesDone = (ruleId: string, from: Day) =>
  run(
    (sql) =>
      sql<{ occurrenceOn: Day }>`SELECT occurrence_on::text AS occurrence_on
        FROM rule_occurrences WHERE rule_id = ${ruleId} AND occurrence_on >= ${from}`,
  ).pipe(Effect.map((rows) => new Set(rows.map((r) => r.occurrenceOn))));

/** True when this call recorded it, false when it was there already. */
export const recordOccurrence = (
  ruleId: string,
  day: Day,
  outcome: "done" | "todo" | "missed",
) =>
  run(
    (sql) =>
      sql<{
        ruleId: string;
      }>`INSERT INTO rule_occurrences (rule_id, occurrence_on, outcome)
        VALUES (${ruleId}, ${day}, ${outcome})
        ON CONFLICT DO NOTHING RETURNING rule_id`,
  ).pipe(Effect.map((rows) => rows.length > 0));

export const setOccurrenceOutcome = (
  ruleId: string,
  day: Day,
  outcome: "done" | "todo" | "missed",
) =>
  run(
    (sql) =>
      sql`UPDATE rule_occurrences SET outcome = ${outcome}
        WHERE rule_id = ${ruleId} AND occurrence_on = ${day}`,
  ).pipe(Effect.asVoid);

// ---- the to-do list --------------------------------------------------------------------------

const todoColumns = (sql: SqlClient.SqlClient) =>
  sql`t.id, t.kind, t.user_id, t.household_id, h.name AS household_name, t.period_id,
    t.rule_id, t.occurrence_on::text AS occurrence_on, t.ref_id,
    COALESCE(x.envelope_id, r.envelope_id) AS envelope_id,
    t.amount_minor::float8 AS amount_minor, t.title, t.created_at`;

export const todoFor = (userId: string) =>
  run(
    (sql) =>
      sql<TodoRow>`SELECT ${todoColumns(sql)}
        FROM todo_items t
        LEFT JOIN recurring_rules r ON r.id = t.rule_id
        LEFT JOIN households h ON h.id = COALESCE(t.household_id, r.household_id)
        LEFT JOIN expenses x ON x.id = t.ref_id
        WHERE t.resolved_at IS NULL
          AND (t.user_id = ${userId}
            OR t.household_id IN (SELECT household_id FROM household_members WHERE user_id = ${userId}))
        ORDER BY t.created_at, t.id`,
  );

export const todoById = (id: string) =>
  run(
    (sql) =>
      sql<TodoRow>`SELECT ${todoColumns(sql)}
        FROM todo_items t
        LEFT JOIN recurring_rules r ON r.id = t.rule_id
        LEFT JOIN households h ON h.id = COALESCE(t.household_id, r.household_id)
        LEFT JOIN expenses x ON x.id = t.ref_id
        WHERE t.id = ${id} AND t.resolved_at IS NULL`,
  ).pipe(Effect.map(first));

export const insertTodo = (row: {
  kind: TodoKind;
  userId?: string | null;
  householdId?: string | null;
  periodId?: string | null;
  ruleId?: string | null;
  occurrenceOn?: Day | null;
  refId?: string | null;
  amountMinor: number;
  title?: string | null;
}) =>
  run(
    (sql) =>
      sql`INSERT INTO todo_items ${sql.insert({
        id: crypto.randomUUID(),
        userId: null,
        householdId: null,
        periodId: null,
        ruleId: null,
        occurrenceOn: null,
        refId: null,
        title: null,
        ...row,
        createdAt: new Date(),
      })} ON CONFLICT DO NOTHING`,
  ).pipe(Effect.asVoid);

export const resolveTodo = (id: string, userId: string | null) =>
  run(
    (sql) =>
      sql`UPDATE todo_items SET resolved_at = now(), resolved_by = ${userId}
        WHERE id = ${id} AND resolved_at IS NULL`,
  ).pipe(Effect.asVoid);

/** What is about an income or expense goes with it. */
export const resolveTodoOfRef = (refId: string, userId: string | null) =>
  run(
    (sql) =>
      sql`UPDATE todo_items SET resolved_at = now(), resolved_by = ${userId}
        WHERE ref_id = ${refId} AND resolved_at IS NULL`,
  ).pipe(Effect.asVoid);

/** A closed period is frozen: nothing about it waits for a decision any more. */
export const resolveTodoOfPeriod = (periodId: string) =>
  run(
    (sql) =>
      sql`UPDATE todo_items SET resolved_at = now()
        WHERE period_id = ${periodId} AND resolved_at IS NULL
          AND kind IN ('expense_estimate', 'expense_not_fit')`,
  ).pipe(Effect.asVoid);

export const countTodo = (userId: string) =>
  todoFor(userId).pipe(Effect.map((rows) => rows.length));

// ---- the change log ---------------------------------------------------------------------------

export const insertLog = (row: {
  householdId: string;
  periodId: string;
  userId: string | null;
  userName: string;
  action: string;
  entityId: string;
  summary: string;
  before: unknown;
  after: unknown;
}) =>
  run(
    (sql) =>
      sql`INSERT INTO change_log (id, household_id, period_id, user_id, user_name,
          action, entity_id, summary, before, after, created_at)
        VALUES (${crypto.randomUUID()}, ${row.householdId}, ${row.periodId}, ${row.userId},
          ${row.userName}, ${row.action}, ${row.entityId}, ${row.summary},
          ${row.before === null || row.before === undefined ? null : JSON.stringify(row.before)}::jsonb,
          ${row.after === null || row.after === undefined ? null : JSON.stringify(row.after)}::jsonb,
          clock_timestamp())`,
  ).pipe(Effect.asVoid);

const logColumns = (sql: SqlClient.SqlClient) =>
  sql`id, household_id, period_id, user_id, user_name, action, entity_id, summary,
    before, after, created_at, undone_at`;

export const logOf = (householdId: string) =>
  run(
    (sql) =>
      sql<LogRow>`SELECT ${logColumns(sql)} FROM change_log
        WHERE household_id = ${householdId} ORDER BY created_at DESC, id`,
  );

export const logById = (id: string) =>
  run(
    (sql) =>
      sql<LogRow>`SELECT ${logColumns(sql)} FROM change_log WHERE id = ${id}`,
  ).pipe(Effect.map(first));

export const markUndone = (id: string, userId: string) =>
  run(
    (sql) =>
      sql`UPDATE change_log SET undone_at = now(), undone_by = ${userId} WHERE id = ${id}`,
  ).pipe(Effect.asVoid);

export const deleteLogOfPeriod = (periodId: string) =>
  run((sql) => sql`DELETE FROM change_log WHERE period_id = ${periodId}`).pipe(
    Effect.asVoid,
  );

// ---- locks ----------------------------------------------------------------------------------

/**
 * Serialises changes to the money of wallets (`w:<user>`) and households
 * (`h:<household>`) until the transaction ends. Always take every lock an
 * operation needs at once: they are taken in one order, so two operations
 * never wait for each other.
 */
export const lock = (keys: ReadonlyArray<string>) =>
  Effect.gen(function* () {
    const sql = yield* SqlClient.SqlClient;
    for (const key of [...new Set(keys)].sort())
      yield* sql`SELECT pg_advisory_xact_lock(hashtext(${key}))`;
  }).pipe(Effect.orDie);
