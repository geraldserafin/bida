import type {
  ClosedSummary,
  Household,
  PeriodSummary,
  UserId,
} from "@bida/api-contract";
import { Effect } from "effect";
import { bankOf, nameOf, openOf, ruleDays, todayIn } from "./core.ts";
import { addDays, daysBetween, localDay, minDay } from "./dates.ts";
import {
  balanceOf,
  carryOf,
  freeOf,
  plansTotalOf,
  remainingPlansOf,
  sharesOf,
  spentOf,
  transfersOf,
  withdrawalsOf,
} from "./money.ts";
import { cycleJson, periodJson, utc } from "./present.ts";
import type { HouseholdRow, MemberRow, PeriodRow } from "./store.ts";
import * as store from "./store.ts";

// What the screens read: a household with its current piggy bank, and the
// figures of one period (F16, F17, F18, F23, F33, F35).

export const householdJson = Effect.fn("summary.householdJson")(function* (
  h: HouseholdRow,
  me: MemberRow,
) {
  const { current, next } = yield* openOf(h.id);
  const members = yield* store.membersOf(h.id);
  const bank = yield* bankOf(current);
  return {
    id: h.id,
    name: h.name,
    timeZone: h.timeZone,
    cycle: cycleJson(h),
    role: me.role,
    frozen: me.frozenAt !== null,
    memberCount: members.length,
    current: periodJson(current, current),
    next: next === null ? null : periodJson(next, current),
    balanceMinor: balanceOf(bank.ledger),
    createdAt: utc(h.createdAt),
  } satisfies Household;
});

const matchesForWhom = (
  forWhom: string | undefined,
  x: { forWhom: string | null; forWhomUserId: string | null },
) =>
  forWhom === undefined ||
  (forWhom === "shared" && x.forWhom === "shared") ||
  (forWhom === "none" && x.forWhom === null) ||
  x.forWhomUserId === forWhom;

/** Needs at least this many different days of spending in the period (F18). */
const FORECAST_MIN_DAYS = 3;

export const periodSummary = Effect.fn("summary.periodSummary")(function* (
  h: HouseholdRow,
  period: PeriodRow,
  forWhom?: string,
) {
  const { current } = yield* openOf(h.id);
  const bank = yield* bankOf(period);
  const { ledger } = bank;
  const envelopes = yield* store.envelopesOf(h.id);
  const previous = yield* store.periodEndingOn(
    h.id,
    addDays(period.startsOn, -1),
  );
  const previousExpenses =
    previous === undefined ? null : yield* store.expensesOf(previous.id);

  const filtered = bank.expenses.filter((x) => matchesForWhom(forWhom, x));
  const filteredTotal = filtered.reduce((s, x) => s + x.amountMinor, 0);
  const used = new Set([
    ...bank.plans.map((p) => p.envelopeId),
    ...bank.expenses.map((x) => x.envelopeId),
  ]);
  const figures = envelopes
    .filter((e) => e.archivedAt === null || used.has(e.id))
    .map((e) => {
      const plan = bank.plans.find((p) => p.envelopeId === e.id);
      const manualMinor = plan?.manualMinor ?? 0;
      const recurringMinor = plan?.recurringMinor ?? 0;
      const planMinor = manualMinor + recurringMinor;
      const spentAll = bank.expenses
        .filter((x) => x.envelopeId === e.id)
        .reduce((s, x) => s + x.amountMinor, 0);
      const spentMinor = filtered
        .filter((x) => x.envelopeId === e.id)
        .reduce((s, x) => s + x.amountMinor, 0);
      return {
        envelopeId: e.id,
        name: e.name,
        color: e.color,
        icon: e.icon,
        archived: e.archivedAt !== null,
        planMinor,
        manualMinor,
        recurringMinor,
        spentMinor,
        leftMinor: planMinor - spentAll,
        sharePercent:
          filteredTotal === 0
            ? 0
            : Math.round((spentMinor / filteredTotal) * 1000) / 10,
        previousSpentMinor:
          previousExpenses === null
            ? null
            : previousExpenses
                .filter(
                  (x) => x.envelopeId === e.id && matchesForWhom(forWhom, x),
                )
                .reduce((s, x) => s + x.amountMinor, 0),
      };
    })
    .sort(
      (a, b) => b.spentMinor - a.spentMinor || a.name.localeCompare(b.name),
    );

  const shares = sharesOf(ledger);
  const members = yield* store.membersOf(h.id);
  const names = new Map<string, string>();
  for (const m of bank.moves)
    if (m.userId !== null && m.userName !== null)
      names.set(m.userId, m.userName);
  for (const x of bank.expenses)
    if (x.createdBy !== null) names.set(x.createdBy, x.authorName);
  for (const m of members) names.set(m.userId, nameOf(m));
  const people = [...shares.people];
  for (const m of members)
    if (!people.some((p) => p.userId === m.userId))
      people.push({
        userId: m.userId,
        transfersMinor: 0,
        withdrawalsMinor: 0,
        forfeitedMinor: 0,
        spentMinor: 0,
        fromNobodyMinor: 0,
        shareMinor: 0,
      });

  const isCurrent = period.closedAt === null && period.id === current.id;
  const spentMinor = spentOf(ledger);
  let forecast: PeriodSummary["forecast"] = null;
  const days = new Set(
    bank.expenses.map((x) => localDay(x.spentAt, h.timeZone)),
  );
  if (isCurrent && days.size >= FORECAST_MIN_DAYS) {
    const today = minDay(todayIn(h.timeZone), period.endsOn);
    const elapsed = daysBetween(period.startsOn, today) + 1;
    const length = daysBetween(period.startsOn, period.endsOn) + 1;
    const variableSpent = bank.expenses
      .filter((x) => x.ruleId === null)
      .reduce((s, x) => s + x.amountMinor, 0);
    const variableMinor = Math.round((variableSpent / elapsed) * length);
    const rules = yield* store.activeExpenseRulesOf(h.id);
    const recurringMinor = rules.reduce(
      (s, r) =>
        s + ruleDays(r, period.startsOn, period.endsOn).length * r.amountMinor,
      0,
    );
    const projectedSpentMinor = variableMinor + recurringMinor;
    forecast = {
      variableMinor,
      recurringMinor,
      projectedSpentMinor,
      projectedBalanceMinor:
        transfersOf(ledger) -
        withdrawalsOf(ledger) +
        carryOf(ledger) -
        projectedSpentMinor,
    };
  }

  const free = freeOf(ledger);
  return {
    period: periodJson(period, current),
    transfersMinor: transfersOf(ledger),
    withdrawalsMinor: withdrawalsOf(ledger),
    carryInMinor: carryOf(ledger),
    spentMinor,
    estimatedSpentMinor: bank.expenses
      .filter((x) => x.estimated)
      .reduce((s, x) => s + x.amountMinor, 0),
    balanceMinor: balanceOf(ledger),
    plansTotalMinor: plansTotalOf(ledger),
    remainingPlansMinor: remainingPlansOf(ledger),
    freeMinor: free,
    plansExceedBalance: free < 0,
    carryOutMinor: period.carryOutMinor,
    nobodyMinor: shares.nobodyMinor,
    nobodyLeftMinor: shares.nobodyLeftMinor,
    envelopes: figures,
    shares: people.map((p) => ({
      userId: p.userId as UserId | null,
      name:
        p.userId === null
          ? "Usunięte konto"
          : (names.get(p.userId) ?? "Usunięte konto"),
      member: p.userId !== null && members.some((m) => m.userId === p.userId),
      transfersMinor: p.transfersMinor,
      withdrawalsMinor: p.withdrawalsMinor,
      forfeitedMinor: p.forfeitedMinor,
      spentMinor: p.spentMinor,
      fromNobodyMinor: p.fromNobodyMinor,
      shareMinor: p.shareMinor,
    })),
    forecast,
  } satisfies PeriodSummary;
});

export const closedSummary = Effect.fn("summary.closedSummary")(function* (
  period: PeriodRow,
  householdName: string,
) {
  const { ledger } = yield* bankOf(period);
  return {
    periodId: period.id,
    householdId: period.householdId,
    householdName,
    startsOn: period.startsOn,
    endsOn: period.endsOn,
    transfersMinor: transfersOf(ledger),
    withdrawalsMinor: withdrawalsOf(ledger),
    carryInMinor: carryOf(ledger),
    spentMinor: spentOf(ledger),
    carryOutMinor: period.carryOutMinor ?? 0,
  } satisfies ClosedSummary;
});
