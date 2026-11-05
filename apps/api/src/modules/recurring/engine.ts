import { Effect } from "effect";
import type {
  HouseholdRow,
  PeriodRow,
  RuleRow,
  UserRow,
} from "../ledger/ledger.module.ts";
import {
  addDays,
  addExpense,
  type Day,
  DEFAULT_TIME_ZONE,
  instantOn,
  openNext,
  openOf,
  ruleDays,
  store,
  todayIn,
  transferIn,
} from "../ledger/ledger.module.ts";

// Steps 3-5 of the app start: what the recurring rules owe, once each. An
// occurrence is recorded before anything is made for it, so running again
// (or two devices at once) never makes it twice.

/** Wallet incomes have no household; their days are counted in Warsaw. */
export const walletToday = () => todayIn(DEFAULT_TIME_ZONE);

const pending = Effect.fn("engine.pending")(function* (
  rule: RuleRow,
  to: Day,
  from: Day = rule.startsOn,
) {
  const done = yield* store.occurrencesDone(rule.id, rule.startsOn);
  return ruleDays(rule, from, to).filter((day) => !done.has(day));
});

export const addRuleIncome = Effect.fn("engine.addRuleIncome")(function* (
  rule: RuleRow,
  day: Day,
  amountMinor: number,
  estimated: boolean,
) {
  if (
    !(yield* store.recordOccurrence(rule.id, day, estimated ? "todo" : "done"))
  )
    return false;
  const id = crypto.randomUUID();
  yield* store.insertWalletEntry({
    id,
    userId: rule.userId,
    kind: "income",
    amountMinor,
    onDate: day,
    note: rule.name,
    estimated,
    ruleId: rule.id,
    occurrenceOn: day,
  });
  if (estimated)
    yield* store.insertTodo({
      kind: "income_estimate",
      userId: rule.userId,
      ruleId: rule.id,
      occurrenceOn: day,
      refId: id,
      amountMinor,
      title: rule.name,
    });
  return true;
});

/** Step 3: an estimated income goes in with its estimate on its day and waits for the real amount. */
export const runIncomes = Effect.fn("engine.runIncomes")(function* (
  user: UserRow,
) {
  let made = 0;
  for (const rule of yield* store.activeRules("income", user.id))
    for (const day of yield* pending(rule, walletToday()))
      if (yield* addRuleIncome(rule, day, rule.amountMinor, rule.estimated))
        made++;
  return made;
});

/** The period a transfer of a day goes to: that of the day, or the one after it; never a closed one. */
export const targetPeriod = Effect.fn("engine.targetPeriod")(function* (
  h: HouseholdRow,
  day: Day,
  target: "current" | "next" | null,
) {
  const { current } = yield* openOf(h.id);
  let period: PeriodRow = (yield* store.periodContaining(h.id, day)) ?? current;
  if (target === "next") {
    const after = yield* store.periodContaining(
      h.id,
      addDays(period.endsOn, 1),
    );
    if (after !== undefined) period = after;
    else if (period.id === current.id)
      period = yield* openNext(h, null).pipe(Effect.orDie);
  }
  return period.closedAt === null ? period : current;
});

export const runTransfer = Effect.fn("engine.runTransfer")(function* (
  rule: RuleRow,
  user: UserRow,
  day: Day,
  amountMinor: number,
) {
  if (rule.householdId === null) return "skipped" as const;
  const h = yield* store.householdById(rule.householdId);
  const member = yield* store.memberOf(rule.householdId, user.id);
  if (h === undefined || member === undefined) return "skipped" as const;
  if (!(yield* store.recordOccurrence(rule.id, day, "done")))
    return "skipped" as const;
  const period = yield* targetPeriod(h, day, rule.target);
  const wallet = yield* store.walletOf(user.id);
  if (wallet.balanceMinor < 0 || wallet.balanceMinor < amountMinor) {
    // not on its own: the user decides in the to-do list
    yield* store.setOccurrenceOutcome(rule.id, day, "todo");
    yield* store.insertTodo({
      kind: "transfer_no_money",
      userId: user.id,
      periodId: period.id,
      ruleId: rule.id,
      occurrenceOn: day,
      amountMinor,
      title: rule.name,
    });
    return "todo" as const;
  }
  // the wallet was checked above
  yield* transferIn(h, period, user, amountMinor, {
    ruleId: rule.id,
    occurrenceOn: day,
  }).pipe(Effect.orDie);
  return "done" as const;
});

/** Step 4. */
export const runTransfers = Effect.fn("engine.runTransfers")(function* (
  user: UserRow,
) {
  let made = 0;
  for (const rule of yield* store.activeRules("transfer", user.id)) {
    if (rule.householdId === null) continue;
    const h = yield* store.householdById(rule.householdId);
    if (h === undefined) continue;
    for (const day of yield* pending(rule, todayIn(h.timeZone)))
      if ((yield* runTransfer(rule, user, day, rule.amountMinor)) === "done")
        made++;
  }
  return made;
});

/**
 * One occurrence of an expense rule in the current period, written by the
 * creator of the rule. One that does not fit waits in the to-do list.
 */
export const runExpense = Effect.fn("engine.runExpense")(function* (
  h: HouseholdRow,
  rule: RuleRow,
  day: Day,
  spentAt: Date,
) {
  if (rule.envelopeId === null) return "skipped" as const;
  if (!(yield* store.recordOccurrence(rule.id, day, "done")))
    return "skipped" as const;
  const period = yield* store.periodContaining(h.id, day);
  if (period !== undefined && period.closedAt !== null) {
    yield* store.setOccurrenceOutcome(rule.id, day, "missed");
    yield* store.insertTodo({
      kind: "expense_missed",
      householdId: h.id,
      ruleId: rule.id,
      occurrenceOn: day,
      amountMinor: rule.amountMinor,
      title: rule.name,
    });
    return "todo" as const;
  }
  const { current } = yield* openOf(h.id);
  const author = yield* store.userById(rule.userId);
  const notFit = () => Effect.succeed({ ok: false as const });
  const outcome =
    author === undefined
      ? { ok: false as const }
      : yield* addExpense(
          h,
          author,
          {
            envelopeId: rule.envelopeId,
            amountMinor: rule.amountMinor,
            spentAt,
            title: rule.name,
            forWhom: null,
            forWhomUserId: null,
          },
          undefined,
          {
            author,
            estimated: rule.estimated,
            ruleId: rule.id,
            occurrenceOn: day,
          },
        ).pipe(
          Effect.map((result) => ({ ok: true as const, result })),
          Effect.catchTags({
            PlanTooSmall: notFit,
            NotEnoughInPeriod: notFit,
            WalletWouldGoNegative: notFit,
            WalletNegative: notFit,
            NotEnoughMoney: notFit,
            PeriodClosed: notFit,
            MemberFrozen: notFit,
            MemberNotFound: notFit,
            EnvelopeNotFound: notFit,
            DateOutsidePeriod: notFit,
            Forbidden: notFit,
          }),
        );
  if (!outcome.ok) {
    yield* store.setOccurrenceOutcome(rule.id, day, "todo");
    yield* store.insertTodo({
      kind: "expense_not_fit",
      householdId: h.id,
      periodId: current.id,
      ruleId: rule.id,
      occurrenceOn: day,
      amountMinor: rule.amountMinor,
      title: rule.name,
    });
    return "todo" as const;
  }
  if (rule.estimated)
    yield* store.insertTodo({
      kind: "expense_estimate",
      householdId: h.id,
      periodId: current.id,
      ruleId: rule.id,
      occurrenceOn: day,
      refId: outcome.result.expense.id,
      amountMinor: rule.amountMinor,
      title: rule.name,
    });
  return "done" as const;
});

/** Step 5: the recurring expenses of a household that fell due. */
export const runExpenses = Effect.fn("engine.runExpenses")(function* (
  h: HouseholdRow,
) {
  let made = 0;
  const today = todayIn(h.timeZone);
  const first = (yield* store.periodsOf(h.id)).at(-1);
  for (const rule of yield* store.activeExpenseRulesOf(h.id))
    for (const day of yield* pending(rule, today)) {
      // before the household had periods: nothing to make
      if (first !== undefined && day < first.startsOn) {
        yield* store.recordOccurrence(rule.id, day, "missed");
        continue;
      }
      const outcome = yield* runExpense(
        h,
        rule,
        day,
        instantOn(day, h.timeZone),
      );
      if (outcome === "done") made++;
    }
  return made;
});

/** The occurrences of a rule not dealt with yet, from a day to another. */
export const pendingDays = pending;
