import {
  DateOutsidePeriod,
  type Decision,
  EnvelopeNotFound,
  Forbidden,
  MemberFrozen,
  MemberNotFound,
  NextPeriodOpen,
  NotEnoughInPeriod,
  NotEnoughMoney,
  PeriodClosed,
  PlanBelowSpent,
  PlanTooSmall,
  WalletNegative,
  WalletWouldGoNegative,
} from "@bida/api-contract";
import { Effect } from "effect";
import { type Cycle, nextPeriod, occurrences, type Span } from "./cycle.ts";
import { type Day, localDay, maxDay } from "./dates.ts";
import {
  balanceOf,
  type ExpenseRequest,
  fitOf,
  freeOf,
  type Ledger,
  planOf,
  type Resolution,
  settle,
  sharesOf,
  spentFrom,
  withdrawableOf,
} from "./money.ts";
import type {
  ExpenseRow,
  HouseholdRow,
  MoveRow,
  PeriodRow,
  PlanRow,
  RuleRow,
  UserRow,
} from "./store.ts";
import * as store from "./store.ts";

// The operations on money that more than one feature needs. They run inside
// the transaction of the caller, which has taken the locks (store.lock).

/** How a person is shown to others. */
export const nameOf = (user: {
  readonly name: string | null;
  readonly email: string;
}) => user.name ?? user.email;

/** 1234 → "12,34 zł", for the change log. */
export const money = (minor: number) => {
  const sign = minor < 0 ? "−" : "";
  const abs = Math.abs(minor);
  return `${sign}${Math.floor(abs / 100)},${String(abs % 100).padStart(2, "0")} zł`;
};

export const cycleOf = (h: HouseholdRow): Cycle => {
  if (h.cycleKind === "monthly")
    return { kind: "monthly", day: h.cycleDay ?? 1 };
  if (h.cycleKind === "weeks")
    return {
      kind: "weeks",
      weeks: h.cycleWeeks ?? 1,
      anchor: h.cycleAnchor ?? "2026-01-05",
    };
  return { kind: "manual" };
};

export const todayIn = (timeZone: string, now = new Date()) =>
  localDay(now, timeZone);

/**
 * An instant on a day in a time zone: noon there, or now when that is still
 * to come (an expense is never dated in the future).
 */
export const instantOn = (day: Day, timeZone: string, now = new Date()) => {
  let instant = new Date(`${day}T12:00:00Z`);
  for (let i = 0; i < 2 && localDay(instant, timeZone) !== day; i++) {
    const shift = localDay(instant, timeZone) > day ? -12 : 12;
    instant = new Date(instant.getTime() + shift * 3_600_000);
  }
  return instant.getTime() > now.getTime() ? now : instant;
};

export const toLedger = (
  moves: ReadonlyArray<MoveRow>,
  expenses: ReadonlyArray<ExpenseRow>,
  plans: ReadonlyArray<PlanRow>,
): Ledger => ({
  moves: moves.map((m) => ({
    userId: m.userId,
    kind: m.kind,
    amountMinor: m.amountMinor,
  })),
  expenses: expenses.map((x) => ({
    id: x.id,
    userId: x.createdBy,
    envelopeId: x.envelopeId,
    amountMinor: x.amountMinor,
    spentAtMs: x.spentAt.getTime(),
    createdAtMs: x.createdAt.getTime(),
  })),
  plans: plans.map((p) => ({
    envelopeId: p.envelopeId,
    manualMinor: p.manualMinor,
    recurringMinor: p.recurringMinor,
  })),
});

export interface Bank {
  readonly period: PeriodRow;
  readonly moves: ReadonlyArray<MoveRow>;
  readonly expenses: ReadonlyArray<ExpenseRow>;
  readonly plans: ReadonlyArray<PlanRow>;
  readonly ledger: Ledger;
}

/** Everything in one piggy bank. */
export const bankOf = Effect.fn("ledger.bankOf")(function* (period: PeriodRow) {
  const moves = yield* store.movesOf(period.id);
  const expenses = yield* store.expensesOf(period.id);
  const plans = yield* store.plansOf(period.id);
  return {
    period,
    moves,
    expenses,
    plans,
    ledger: toLedger(moves, expenses, plans),
  } satisfies Bank;
});

/** The current period and, when it is open, the next one. A household always has a current one. */
export const openOf = Effect.fn("ledger.openOf")(function* (
  householdId: string,
) {
  const open = yield* store.openPeriodsOf(householdId);
  const current = open[0];
  if (current === undefined)
    return yield* Effect.die(`household ${householdId} has no open period`);
  return { current, next: open[1] ?? null };
});

export const statusOf = (
  period: PeriodRow,
  current: PeriodRow,
): "current" | "next" | "closed" =>
  period.closedAt !== null
    ? "closed"
    : period.id === current.id
      ? "current"
      : "next";

// ---- the change log ----------------------------------------------------------------------

export const logChange = (
  h: HouseholdRow,
  periodId: string,
  actor: UserRow | null,
  action: string,
  entityId: string,
  summary: string,
  before: unknown = null,
  after: unknown = null,
) =>
  store.insertLog({
    householdId: h.id,
    periodId,
    userId: actor?.id ?? null,
    userName: actor === null ? "Aplikacja" : nameOf(actor),
    action,
    entityId,
    summary,
    before,
    after,
  });

// ---- plans --------------------------------------------------------------------------------

const scheduleOf = (rule: RuleRow) =>
  rule.frequency === "monthly"
    ? { frequency: "monthly" as const, dayOfMonth: rule.dayOfMonth ?? 1 }
    : {
        frequency: "weeks" as const,
        everyWeeks: rule.everyWeeks ?? 1,
        anchorOn: rule.anchorOn ?? rule.startsOn,
      };

/** The days a rule falls on in a span, not before the rule starts. */
export const ruleDays = (rule: RuleRow, from: Day, to: Day) =>
  occurrences(scheduleOf(rule), maxDay(from, rule.startsOn), to);

/** The recurring part of the plans of a span: amount × occurrences, per envelope. */
export const recurringParts = (rules: ReadonlyArray<RuleRow>, span: Span) => {
  const parts = new Map<string, number>();
  for (const rule of rules) {
    if (rule.envelopeId === null) continue;
    const count = ruleDays(rule, span.startsOn, span.endsOn).length;
    if (count === 0) continue;
    parts.set(
      rule.envelopeId,
      (parts.get(rule.envelopeId) ?? 0) + count * rule.amountMinor,
    );
  }
  return parts;
};

/**
 * Recounts the recurring part of the plans of the open periods (after the
 * rules or the bounds changed). A plan never ends up below what was spent.
 */
export const refreshPlans = Effect.fn("ledger.refreshPlans")(function* (
  householdId: string,
) {
  const rules = yield* store.activeExpenseRulesOf(householdId);
  for (const period of yield* store.openPeriodsOf(householdId)) {
    const bank = yield* bankOf(period);
    const parts = recurringParts(rules, period);
    const envelopes = new Set([
      ...bank.plans.map((p) => p.envelopeId),
      ...parts.keys(),
    ]);
    for (const envelopeId of envelopes) {
      const row = bank.plans.find((p) => p.envelopeId === envelopeId);
      const recurringMinor = parts.get(envelopeId) ?? 0;
      let manualMinor = row?.manualMinor ?? 0;
      const spent = spentFrom(bank.ledger, envelopeId);
      if (manualMinor + recurringMinor < spent)
        manualMinor = spent - recurringMinor;
      if (manualMinor + recurringMinor < 0) manualMinor = -recurringMinor;
      if (
        row === undefined ||
        row.manualMinor !== manualMinor ||
        row.recurringMinor !== recurringMinor
      )
        yield* store.upsertPlan({
          periodId: period.id,
          envelopeId,
          manualMinor,
          recurringMinor,
        });
    }
  }
});

/** Sets the plan the user sees; the manual part takes the difference. */
export const setPlanTotal = Effect.fn("ledger.setPlanTotal")(function* (
  h: HouseholdRow,
  period: PeriodRow,
  envelopeId: string,
  totalMinor: number,
  actor: UserRow | null,
) {
  if (period.closedAt !== null)
    return yield* new PeriodClosed({ periodId: period.id });
  const envelope = yield* store.envelopeById(envelopeId);
  if (envelope === undefined || envelope.householdId !== h.id)
    return yield* new EnvelopeNotFound({ id: envelopeId });
  const bank = yield* bankOf(period);
  const spent = spentFrom(bank.ledger, envelopeId);
  if (totalMinor < spent)
    return yield* new PlanBelowSpent({ envelopeId, spentMinor: spent });
  const row = bank.plans.find((p) => p.envelopeId === envelopeId);
  const recurringMinor = row?.recurringMinor ?? 0;
  const before = planOf(bank.ledger, envelopeId);
  yield* store.upsertPlan({
    periodId: period.id,
    envelopeId,
    manualMinor: totalMinor - recurringMinor,
    recurringMinor,
  });
  if (before !== totalMinor)
    yield* logChange(
      h,
      period.id,
      actor,
      "plan.set",
      envelopeId,
      `Plan „${envelope.name}”: ${money(before)} → ${money(totalMinor)}`,
      { periodId: period.id, envelopeId, totalMinor: before },
      { periodId: period.id, envelopeId, totalMinor },
    );
});

const raisePlan = Effect.fn("ledger.raisePlan")(function* (
  bank: Bank,
  envelopeId: string,
  byMinor: number,
) {
  const row = bank.plans.find((p) => p.envelopeId === envelopeId);
  yield* store.upsertPlan({
    periodId: bank.period.id,
    envelopeId,
    manualMinor: (row?.manualMinor ?? 0) + byMinor,
    recurringMinor: row?.recurringMinor ?? 0,
  });
});

// ---- periods -------------------------------------------------------------------------------

/** A new open period after `copyFrom` (or the first one), with the manual plans copied. */
export const createPeriod = Effect.fn("ledger.createPeriod")(function* (
  householdId: string,
  span: Span,
  copyFrom: PeriodRow | null,
) {
  const id = crypto.randomUUID();
  yield* store.insertPeriod({
    id,
    householdId,
    startsOn: span.startsOn,
    endsOn: span.endsOn,
  });
  const previous = copyFrom === null ? [] : yield* store.plansOf(copyFrom.id);
  const rules = yield* store.activeExpenseRulesOf(householdId);
  const parts = recurringParts(rules, span);
  for (const envelope of yield* store.envelopesOf(householdId)) {
    if (envelope.archivedAt !== null) continue;
    const recurringMinor = parts.get(envelope.id) ?? 0;
    const manual =
      previous.find((p) => p.envelopeId === envelope.id)?.manualMinor ?? 0;
    yield* store.upsertPlan({
      periodId: id,
      envelopeId: envelope.id,
      manualMinor: Math.max(manual, -recurringMinor),
      recurringMinor,
    });
  }
  const period = yield* store.periodById(id);
  if (period === undefined) return yield* Effect.die("period vanished");
  return period;
});

export const openNext = Effect.fn("ledger.openNext")(function* (
  h: HouseholdRow,
  actor: UserRow | null,
) {
  const { current, next } = yield* openOf(h.id);
  if (next !== null) return yield* new NextPeriodOpen({ periodId: next.id });
  const period = yield* createPeriod(
    h.id,
    nextPeriod(cycleOf(h), current),
    current,
  );
  yield* logChange(
    h,
    period.id,
    actor,
    "period.next",
    period.id,
    `Otwarto okres ${period.startsOn} – ${period.endsOn}`,
  );
  return period;
});

/**
 * Step 1 and 2 of the app start: closes every period that ended. What is left
 * in it goes to the next one as nobody's money; the next one is opened when
 * it is not open yet. Returns how many were closed and opened.
 */
export const closeDue = Effect.fn("ledger.closeDue")(function* (
  h: HouseholdRow,
  today: Day,
) {
  let closed = 0;
  let opened = 0;
  for (;;) {
    const { current, next: open } = yield* openOf(h.id);
    if (current.endsOn >= today) break;
    let next = open;
    if (next === null) {
      next = yield* createPeriod(
        h.id,
        nextPeriod(cycleOf(h), current),
        current,
      );
      opened++;
    }
    const bank = yield* bankOf(current);
    const carry = Math.max(balanceOf(bank.ledger), 0);
    yield* store.closePeriod(current.id, carry);
    if (carry > 0)
      yield* store.insertMove({
        id: crypto.randomUUID(),
        periodId: next.id,
        householdId: h.id,
        userId: null,
        userName: null,
        kind: "carry",
        amountMinor: carry,
      });
    yield* store.deleteLogOfPeriod(current.id);
    yield* store.resolveTodoOfPeriod(current.id);
    closed++;
  }
  if (closed > 0) yield* releaseSettledFrozen(h);
  return { closed, opened };
});

// ---- shares, leaving --------------------------------------------------------------------------

export interface NegativeEntry {
  readonly householdId: string;
  readonly householdName: string;
  readonly periodId: string;
  readonly userId: string;
  readonly shareMinor: number;
}

/** Negative shares in the open periods, of everybody or of the people named. */
export const negativeShares = Effect.fn("ledger.negativeShares")(function* (
  h: HouseholdRow,
  userIds?: ReadonlyArray<string>,
) {
  const found: Array<NegativeEntry> = [];
  for (const period of yield* store.openPeriodsOf(h.id)) {
    const bank = yield* bankOf(period);
    for (const share of sharesOf(bank.ledger).people) {
      if (share.userId === null || share.shareMinor >= 0) continue;
      if (userIds !== undefined && !userIds.includes(share.userId)) continue;
      found.push({
        householdId: h.id,
        householdName: h.name,
        periodId: period.id,
        userId: share.userId,
        shareMinor: share.shareMinor,
      });
    }
  }
  return found;
});

/**
 * Ends the money of a person in the open periods: `withdraw` takes their
 * share back to the wallet (`return` the same, marked as given back), as far
 * as the piggy bank has it, the rest stays as nobody's; `forfeit` leaves all
 * of it as nobody's money.
 */
export const settleShares = Effect.fn("ledger.settleShares")(function* (
  h: HouseholdRow,
  user: UserRow,
  mode: "withdraw" | "return" | "forfeit",
) {
  for (const period of yield* store.openPeriodsOf(h.id)) {
    const bank = yield* bankOf(period);
    const share =
      sharesOf(bank.ledger).people.find((p) => p.userId === user.id)
        ?.shareMinor ?? 0;
    if (share <= 0) continue;
    const take =
      mode === "forfeit" ? 0 : Math.min(share, balanceOf(bank.ledger));
    if (take > 0) {
      const moveId = crypto.randomUUID();
      yield* store.insertMove({
        id: moveId,
        periodId: period.id,
        householdId: h.id,
        userId: user.id,
        userName: nameOf(user),
        kind: "withdrawal",
        amountMinor: take,
      });
      yield* store.insertWalletEntry({
        id: crypto.randomUUID(),
        userId: user.id,
        kind: mode === "withdraw" ? "withdrawal" : "return",
        amountMinor: take,
        onDate: todayIn(h.timeZone),
        moveId,
        householdId: h.id,
        householdName: h.name,
      });
    }
    if (share - take > 0)
      yield* store.insertMove({
        id: crypto.randomUUID(),
        periodId: period.id,
        householdId: h.id,
        userId: user.id,
        userName: nameOf(user),
        kind: "forfeit",
        amountMinor: share - take,
      });
  }
});

/** Takes a person out of a household; their rules about it stop. */
export const removeMember = Effect.fn("ledger.removeMember")(function* (
  h: HouseholdRow,
  user: UserRow,
  mode: "withdraw" | "return" | "forfeit",
) {
  yield* settleShares(h, user, mode);
  yield* store.deleteMember(h.id, user.id);
  yield* store.deactivateRulesOf(h.id, user.id);
});

/** A frozen member goes once no share of theirs is negative (F36). */
export const releaseSettledFrozen = Effect.fn("ledger.releaseSettledFrozen")(
  function* (h: HouseholdRow) {
    for (const member of yield* store.membersOf(h.id)) {
      if (member.frozenAt === null) continue;
      if ((yield* negativeShares(h, [member.userId])).length > 0) continue;
      yield* removeMember(
        h,
        { id: member.userId, email: member.email, name: member.name },
        "return",
      );
    }
  },
);

// ---- transfers ------------------------------------------------------------------------------

export const transferIn = Effect.fn("ledger.transferIn")(function* (
  h: HouseholdRow,
  period: PeriodRow,
  actor: UserRow,
  amountMinor: number,
  options: {
    readonly allowNegative?: boolean;
    readonly ruleId?: string;
    readonly occurrenceOn?: Day;
  } = {},
) {
  if (period.closedAt !== null)
    return yield* new PeriodClosed({ periodId: period.id });
  const wallet = yield* store.walletOf(actor.id);
  if (options.allowNegative !== true) {
    if (wallet.balanceMinor < 0)
      return yield* new WalletNegative({ walletMinor: wallet.balanceMinor });
    if (amountMinor > wallet.balanceMinor)
      return yield* new NotEnoughMoney({ availableMinor: wallet.balanceMinor });
  }
  const moveId = crypto.randomUUID();
  yield* store.insertMove({
    id: moveId,
    periodId: period.id,
    householdId: h.id,
    userId: actor.id,
    userName: nameOf(actor),
    kind: "transfer",
    amountMinor,
    ruleId: options.ruleId ?? null,
    occurrenceOn: options.occurrenceOn ?? null,
  });
  yield* store.insertWalletEntry({
    id: crypto.randomUUID(),
    userId: actor.id,
    kind: "transfer",
    amountMinor,
    onDate: todayIn(h.timeZone),
    moveId,
    householdId: h.id,
    householdName: h.name,
    ruleId: options.ruleId ?? null,
    occurrenceOn: options.occurrenceOn ?? null,
  });
  yield* logChange(
    h,
    period.id,
    actor,
    "transfer",
    moveId,
    `Przelew z portfela: ${money(amountMinor)}`,
  );
  const member = yield* store.memberOf(h.id, actor.id);
  if (member?.frozenAt !== null && member !== undefined)
    yield* releaseSettledFrozen(h);
  const move = yield* store.moveById(moveId);
  if (move === undefined) return yield* Effect.die("move vanished");
  return {
    move,
    walletMinor: wallet.balanceMinor - amountMinor,
    usedUnconfirmed:
      wallet.balanceMinor - wallet.unconfirmedMinor < amountMinor,
  };
});

export const withdrawOut = Effect.fn("ledger.withdrawOut")(function* (
  h: HouseholdRow,
  period: PeriodRow,
  actor: UserRow,
  amountMinor: number,
) {
  if (period.closedAt !== null)
    return yield* new PeriodClosed({ periodId: period.id });
  const bank = yield* bankOf(period);
  const available = withdrawableOf(bank.ledger, actor.id);
  if (amountMinor > available)
    return yield* new NotEnoughMoney({ availableMinor: available });
  const moveId = crypto.randomUUID();
  yield* store.insertMove({
    id: moveId,
    periodId: period.id,
    householdId: h.id,
    userId: actor.id,
    userName: nameOf(actor),
    kind: "withdrawal",
    amountMinor,
  });
  yield* store.insertWalletEntry({
    id: crypto.randomUUID(),
    userId: actor.id,
    kind: "withdrawal",
    amountMinor,
    onDate: todayIn(h.timeZone),
    moveId,
    householdId: h.id,
    householdName: h.name,
  });
  yield* logChange(
    h,
    period.id,
    actor,
    "withdrawal",
    moveId,
    `Wycofanie do portfela: ${money(amountMinor)}`,
  );
  const move = yield* store.moveById(moveId);
  if (move === undefined) return yield* Effect.die("move vanished");
  const wallet = yield* store.walletOf(actor.id);
  return { move, walletMinor: wallet.balanceMinor, usedUnconfirmed: false };
});

/** The plans exceed the balance of the period ("Plan przekracza saldo gospodarstwa"). */
export const plansExceed = Effect.fn("ledger.plansExceed")(function* (
  period: PeriodRow,
) {
  return freeOf((yield* bankOf(period)).ledger) < 0;
});

// ---- expenses -----------------------------------------------------------------------------

export interface ExpenseInput {
  readonly envelopeId: string;
  readonly amountMinor: number;
  readonly spentAt: Date;
  readonly title: string | null;
  readonly forWhom: "member" | "shared" | null;
  readonly forWhomUserId: string | null;
}

/** A few minutes of clock difference between phone and server are fine. */
const CLOCK_SLACK_MS = 5 * 60_000;

const checkDate = (h: HouseholdRow, current: PeriodRow, spentAt: Date) => {
  const day = localDay(spentAt, h.timeZone);
  if (
    day < current.startsOn ||
    day > current.endsOn ||
    spentAt.getTime() > Date.now() + CLOCK_SLACK_MS
  )
    return Effect.fail(
      new DateOutsidePeriod({
        periodId: current.id,
        startsOn: current.startsOn,
        endsOn: current.endsOn,
      }),
    );
  return Effect.void;
};

const forWhomOf = Effect.fn("ledger.forWhomOf")(function* (
  h: HouseholdRow,
  input: ExpenseInput,
) {
  if (input.forWhom !== "member")
    return { forWhom: input.forWhom, forWhomUserId: null, forWhomName: null };
  const member =
    input.forWhomUserId === null
      ? undefined
      : yield* store.memberOf(h.id, input.forWhomUserId);
  if (member === undefined)
    return yield* new MemberNotFound({ userId: input.forWhomUserId ?? "" });
  return {
    forWhom: "member" as const,
    forWhomUserId: member.userId,
    forWhomName: nameOf(member),
  };
});

const activeEnvelope = Effect.fn("ledger.activeEnvelope")(function* (
  h: HouseholdRow,
  envelopeId: string,
) {
  const envelope = yield* store.envelopeById(envelopeId);
  if (
    envelope === undefined ||
    envelope.householdId !== h.id ||
    envelope.archivedAt !== null
  )
    return yield* new EnvelopeNotFound({ id: envelopeId });
  return envelope;
});

/**
 * The steps of F08: fits; the plan grows on its own out of free money; or
 * the user has to decide (raise the plan, bring money from the wallet, let
 * the wallet go below zero). Returns what to transfer and by how much to
 * raise the plan.
 */
const decide = Effect.fn("ledger.decide")(function* (
  bank: Bank,
  actor: UserRow,
  request: ExpenseRequest,
  decision: Decision | undefined,
) {
  const fit = fitOf(bank.ledger, request);
  if (fit.kind === "fits") return { transferMinor: 0, raiseMinor: 0 };
  if (fit.kind === "raise")
    return { transferMinor: 0, raiseMinor: fit.raiseMinor };
  const refuse = () =>
    fit.planShortMinor > 0
      ? new PlanTooSmall({
          envelopeId: request.envelopeId,
          planShortMinor: fit.planShortMinor,
          freeMinor: fit.freeMinor,
          balanceMinor: fit.balanceMinor,
          transferMinor: fit.transferMinor,
        })
      : new NotEnoughInPeriod({
          periodId: bank.period.id,
          balanceMinor: fit.balanceMinor,
          transferMinor: fit.transferMinor,
        });
  if (decision === undefined) return yield* refuse();
  const resolution: Resolution = {
    raisePlan: decision.raisePlan,
    transferMinor: decision.transferMinor,
  };
  const settled = settle(bank.ledger, request, resolution);
  if (!settled.ok) return yield* refuse();
  if (decision.transferMinor > 0) {
    const wallet = yield* store.walletOf(actor.id);
    if (
      wallet.balanceMinor - decision.transferMinor < 0 &&
      !decision.allowNegativeWallet
    )
      return yield* new WalletWouldGoNegative({
        walletMinor: wallet.balanceMinor,
        neededMinor: decision.transferMinor,
      });
  }
  return {
    transferMinor: decision.transferMinor,
    raiseMinor: settled.raiseMinor,
  };
});

export interface AddOptions {
  /** Who the expense is by; the actor when left out (a rule: its creator). */
  readonly author?: UserRow;
  readonly id?: string;
  readonly estimated?: boolean;
  readonly ruleId?: string | null;
  readonly occurrenceOn?: Day | null;
  /** Not logged (undoing a delete puts the expense back as it was). */
  readonly quiet?: boolean;
}

/** Adds an expense to the current period (F08). */
export const addExpense = Effect.fn("ledger.addExpense")(function* (
  h: HouseholdRow,
  actor: UserRow,
  input: ExpenseInput,
  decision: Decision | undefined,
  options: AddOptions = {},
) {
  const author = options.author ?? actor;
  const member = yield* store.memberOf(h.id, author.id);
  if (member === undefined) return yield* new Forbidden();
  if (member.frozenAt !== null) return yield* new MemberFrozen();
  const { current } = yield* openOf(h.id);
  yield* checkDate(h, current, input.spentAt);
  yield* activeEnvelope(h, input.envelopeId);
  const forWhom = yield* forWhomOf(h, input);
  let bank = yield* bankOf(current);
  const request = {
    envelopeId: input.envelopeId,
    amountMinor: input.amountMinor,
  };
  const { transferMinor, raiseMinor } = yield* decide(
    bank,
    actor,
    request,
    decision,
  );
  if (transferMinor > 0) {
    yield* transferIn(h, current, actor, transferMinor, {
      allowNegative: decision?.allowNegativeWallet === true,
    });
    bank = yield* bankOf(current);
  }
  if (raiseMinor > 0) yield* raisePlan(bank, input.envelopeId, raiseMinor);
  const row: store.NewExpense = {
    id: options.id ?? crypto.randomUUID(),
    periodId: current.id,
    householdId: h.id,
    envelopeId: input.envelopeId,
    createdBy: author.id,
    authorName: nameOf(author),
    amountMinor: input.amountMinor,
    spentAt: input.spentAt,
    title: input.title,
    ...forWhom,
    estimated: options.estimated ?? false,
    ruleId: options.ruleId ?? null,
    occurrenceOn: options.occurrenceOn ?? null,
  };
  yield* store.insertExpense(row);
  const saved = yield* store.expenseById(row.id);
  if (saved === undefined) return yield* Effect.die("expense vanished");
  if (options.quiet !== true)
    yield* logChange(
      h,
      current.id,
      actor,
      "expense.create",
      saved.id,
      `Wydatek ${money(saved.amountMinor)}${saved.title === null ? "" : ` „${saved.title}”`}`,
      null,
      { id: saved.id },
    );
  return {
    expense: saved,
    transferredMinor: transferMinor,
    raisedPlanMinor: raiseMinor,
    plansExceedBalance: yield* plansExceed(current),
  };
});

/** The fields of an expense an undo can put back. */
export const expenseInputOf = (x: ExpenseRow): ExpenseInput => ({
  envelopeId: x.envelopeId,
  amountMinor: x.amountMinor,
  spentAt: x.spentAt,
  title: x.title,
  forWhom: x.forWhom,
  forWhomUserId: x.forWhomUserId,
});

export const canChangeExpense = Effect.fn("ledger.canChangeExpense")(function* (
  h: HouseholdRow,
  actor: UserRow,
  expense: ExpenseRow,
) {
  const member = yield* store.memberOf(h.id, actor.id);
  return (
    member !== undefined &&
    (member.role === "owner" || expense.createdBy === actor.id)
  );
});

/** Edits an expense (F09): the steps of F08 in an open period, only the title in a closed one. */
export const updateExpense = Effect.fn("ledger.updateExpense")(function* (
  h: HouseholdRow,
  actor: UserRow,
  expense: ExpenseRow,
  input: ExpenseInput,
  decision: Decision | undefined,
  options: {
    readonly confirmEstimate?: boolean;
    readonly quiet?: boolean;
  } = {},
) {
  if (!(yield* canChangeExpense(h, actor, expense)))
    return yield* new Forbidden();
  const period = yield* store.periodById(expense.periodId);
  if (period === undefined) return yield* Effect.die("period vanished");
  const onlyTitle =
    input.envelopeId === expense.envelopeId &&
    input.amountMinor === expense.amountMinor &&
    input.spentAt.getTime() === expense.spentAt.getTime() &&
    input.forWhom === expense.forWhom &&
    (input.forWhom !== "member" ||
      input.forWhomUserId === expense.forWhomUserId);
  if (period.closedAt !== null) {
    if (!onlyTitle) return yield* new PeriodClosed({ periodId: period.id });
    yield* store.setExpenseTitle(expense.id, input.title);
    const saved = yield* store.expenseById(expense.id);
    if (saved === undefined) return yield* Effect.die("expense vanished");
    return {
      expense: saved,
      transferredMinor: 0,
      raisedPlanMinor: 0,
      plansExceedBalance: false,
    };
  }
  if (!onlyTitle) {
    const member = yield* store.memberOf(h.id, actor.id);
    if (member?.frozenAt !== null && member !== undefined)
      return yield* new MemberFrozen();
    yield* checkDate(h, period, input.spentAt);
  }
  if (input.envelopeId !== expense.envelopeId)
    yield* activeEnvelope(h, input.envelopeId);
  const forWhom = yield* forWhomOf(h, input);
  let bank = yield* bankOf(period);
  const request = {
    envelopeId: input.envelopeId,
    amountMinor: input.amountMinor,
    replacingId: expense.id,
  };
  const { transferMinor, raiseMinor } = yield* decide(
    bank,
    actor,
    request,
    decision,
  );
  if (transferMinor > 0) {
    yield* transferIn(h, period, actor, transferMinor, {
      allowNegative: decision?.allowNegativeWallet === true,
    });
    bank = yield* bankOf(period);
  }
  if (raiseMinor > 0) yield* raisePlan(bank, input.envelopeId, raiseMinor);
  const confirmed =
    options.confirmEstimate === true ||
    input.amountMinor !== expense.amountMinor;
  yield* store.updateExpense(expense.id, {
    periodId: period.id,
    envelopeId: input.envelopeId,
    amountMinor: input.amountMinor,
    spentAt: input.spentAt,
    title: input.title,
    ...forWhom,
    estimated: expense.estimated && !confirmed,
  });
  if (expense.estimated && confirmed)
    yield* store.resolveTodoOfRef(expense.id, actor.id);
  const saved = yield* store.expenseById(expense.id);
  if (saved === undefined) return yield* Effect.die("expense vanished");
  if (options.quiet !== true)
    yield* logChange(
      h,
      period.id,
      actor,
      "expense.update",
      saved.id,
      `Zmiana wydatku: ${money(expense.amountMinor)} → ${money(saved.amountMinor)}`,
      { ...expenseInputOf(expense), spentAt: expense.spentAt.toISOString() },
      { ...expenseInputOf(saved), spentAt: saved.spentAt.toISOString() },
    );
  return {
    expense: saved,
    transferredMinor: transferMinor,
    raisedPlanMinor: raiseMinor,
    plansExceedBalance: yield* plansExceed(period),
  };
});

export const deleteExpense = Effect.fn("ledger.deleteExpense")(function* (
  h: HouseholdRow,
  actor: UserRow,
  expense: ExpenseRow,
  options: { readonly quiet?: boolean } = {},
) {
  if (!(yield* canChangeExpense(h, actor, expense)))
    return yield* new Forbidden();
  const period = yield* store.periodById(expense.periodId);
  if (period === undefined || period.closedAt !== null)
    return yield* new PeriodClosed({ periodId: expense.periodId });
  yield* store.deleteExpense(expense.id);
  yield* store.resolveTodoOfRef(expense.id, actor.id);
  if (options.quiet !== true)
    yield* logChange(
      h,
      period.id,
      actor,
      "expense.delete",
      expense.id,
      `Usunięto wydatek ${money(expense.amountMinor)}${expense.title === null ? "" : ` „${expense.title}”`}`,
      {
        ...expenseInputOf(expense),
        spentAt: expense.spentAt.toISOString(),
        createdBy: expense.createdBy,
        estimated: expense.estimated,
      },
    );
});

// ---- the next period follows the current end -------------------------------------------------

/**
 * Moves the end of the current period. With the next period open, it starts
 * the day after and is recounted by the cycle from there; what was put into
 * it stays in it.
 */
export const moveEnd = (
  h: HouseholdRow,
  current: PeriodRow,
  next: PeriodRow | null,
  endsOn: Day,
  cycle: Cycle,
) =>
  Effect.gen(function* () {
    yield* store.setPeriodBounds(current.id, current.startsOn, endsOn);
    if (next !== null) {
      const span = nextPeriod(cycle, { startsOn: current.startsOn, endsOn });
      yield* store.setPeriodBounds(next.id, span.startsOn, span.endsOn);
    }
    yield* refreshPlans(h.id);
  });
