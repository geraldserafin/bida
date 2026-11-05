import type {
  Envelope,
  Expense,
  Invitation,
  Member,
  Move,
  Period,
  RecurringRule,
  TodoItem,
  UserId,
  WalletEntry,
} from "@bida/api-contract";
import { DateTime } from "effect";
import type {
  EnvelopeRow,
  ExpenseRow,
  HouseholdRow,
  InvitationRow,
  MemberRow,
  MoveRow,
  PeriodRow,
  RuleRow,
  TodoRow,
  WalletEntryRow,
} from "./store.ts";

// Rows of the database in the shapes of the contract.

export const utc = (date: Date) => DateTime.makeUnsafe(date);

const user = (id: string) => id as UserId;
const userOrNull = (id: string | null) => (id === null ? null : user(id));

export const cycleJson = (h: HouseholdRow) => ({
  kind: h.cycleKind,
  day: h.cycleKind === "monthly" ? h.cycleDay : null,
  weeks: h.cycleKind === "weeks" ? h.cycleWeeks : null,
  anchorOn: h.cycleKind === "weeks" ? h.cycleAnchor : null,
});

export const periodJson = (period: PeriodRow, current: PeriodRow): Period => ({
  id: period.id,
  householdId: period.householdId,
  startsOn: period.startsOn,
  endsOn: period.endsOn,
  status:
    period.closedAt !== null
      ? "closed"
      : period.id === current.id
        ? "current"
        : "next",
});

export const memberJson = (m: MemberRow, shareMinor: number): Member => ({
  userId: user(m.userId),
  email: m.email,
  name: m.name,
  role: m.role,
  frozen: m.frozenAt !== null,
  joinedAt: utc(m.joinedAt),
  shareMinor,
});

export const invitationJson = (row: InvitationRow): Invitation => ({
  id: row.id,
  householdId: row.householdId,
  householdName: row.householdName,
  email: row.email,
  role: row.role,
  invitedBy:
    row.invitedByEmail === null
      ? null
      : { email: row.invitedByEmail, name: row.invitedByName },
  expiresAt: utc(row.expiresAt),
  createdAt: utc(row.createdAt),
});

export const envelopeJson = (e: EnvelopeRow): Envelope => ({
  id: e.id,
  householdId: e.householdId,
  name: e.name,
  color: e.color,
  icon: e.icon,
  position: e.position,
  archived: e.archivedAt !== null,
});

export const expenseJson = (x: ExpenseRow): Expense => ({
  id: x.id,
  householdId: x.householdId,
  periodId: x.periodId,
  envelopeId: x.envelopeId,
  createdBy: userOrNull(x.createdBy),
  authorName: x.authorName,
  amountMinor: x.amountMinor,
  spentAt: utc(x.spentAt),
  title: x.title,
  forWhom: x.forWhom,
  forWhomUserId: userOrNull(x.forWhomUserId),
  forWhomName: x.forWhomName,
  estimated: x.estimated,
  ruleId: x.ruleId,
  createdAt: utc(x.createdAt),
  updatedAt: utc(x.updatedAt),
});

export const moveJson = (m: MoveRow): Move => ({
  id: m.id,
  periodId: m.periodId,
  kind: m.kind,
  userId: userOrNull(m.userId),
  userName: m.userName,
  amountMinor: m.amountMinor,
  madeAt: utc(m.madeAt),
  ruleId: m.ruleId,
});

export const walletEntryJson = (w: WalletEntryRow): WalletEntry => ({
  id: w.id,
  kind: w.kind,
  amountMinor: w.amountMinor,
  onDate: w.onDate,
  note: w.note,
  estimated: w.estimated,
  householdId: w.householdId,
  householdName: w.householdName,
  ruleId: w.ruleId,
  createdAt: utc(w.createdAt),
});

export const ruleJson = (r: RuleRow): RecurringRule => ({
  id: r.id,
  kind: r.kind,
  userId: user(r.userId),
  householdId: r.householdId,
  envelopeId: r.envelopeId,
  name: r.name,
  amountMinor: r.amountMinor,
  estimated: r.estimated,
  frequency: r.frequency,
  dayOfMonth: r.dayOfMonth,
  everyWeeks: r.everyWeeks,
  anchorOn: r.anchorOn,
  startsOn: r.startsOn,
  target: r.target,
  active: r.active,
});

export const todoJson = (t: TodoRow): TodoItem => ({
  id: t.id,
  kind: t.kind,
  householdId: t.householdId,
  householdName: t.householdName,
  periodId: t.periodId,
  ruleId: t.ruleId,
  refId: t.refId,
  envelopeId: t.envelopeId,
  occurrenceOn: t.occurrenceOn,
  amountMinor: t.amountMinor,
  title: t.title,
  createdAt: utc(t.createdAt),
});
