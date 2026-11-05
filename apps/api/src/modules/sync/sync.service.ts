import {
  Forbidden,
  PeriodNotFound,
  type ResolveTodo,
  TodoNotFound,
  type UserId,
} from "@bida/api-contract";
import { Effect } from "effect";
import type { TodoRow, UserRow } from "../ledger/ledger.module.ts";
import {
  addExpense,
  balanceOf,
  bankOf,
  closeDue,
  closedSummary,
  expenseInputOf,
  freeOf,
  householdFor,
  householdKey,
  inTx,
  openOf,
  periodFor,
  periodJson,
  store,
  todayIn,
  todoJson,
  transferIn,
  updateExpense,
  userOf,
  walletKey,
} from "../ledger/ledger.module.ts";
import { engine } from "../recurring/recurring.module.ts";
import { wallet } from "../wallet/wallet.module.ts";

export const summaries = Effect.fn("sync.summaries")(function* (
  userId: UserId,
) {
  const unseen = yield* store.unseenClosed(userId);
  return yield* Effect.forEach(unseen, (p) =>
    closedSummary(p, p.householdName),
  );
});

/**
 * What is due, at the app start (F34), in the order of SWS v0.5 chapter 9:
 * closing the periods that ended and opening the new ones, then incomes,
 * transfers and expenses of the recurring rules. Doing it again does
 * nothing twice.
 */
export const run = Effect.fn("sync.run")(function* (userId: UserId) {
  const user = yield* userOf(userId);
  const households = yield* store.householdsOf(userId);
  const counts = yield* inTx(
    [walletKey(userId), ...households.map((h) => householdKey(h.id))],
    Effect.gen(function* () {
      let closedPeriods = 0;
      let openedPeriods = 0;
      for (const h of households) {
        const done = yield* closeDue(h, todayIn(h.timeZone));
        closedPeriods += done.closed;
        openedPeriods += done.opened;
      }
      const incomes = yield* engine.runIncomes(user);
      const transfers = yield* engine.runTransfers(user);
      let expenses = 0;
      for (const h of households) {
        // a household the user just got removed from (frozen and settled)
        if ((yield* store.memberOf(h.id, userId)) === undefined) continue;
        expenses += yield* engine.runExpenses(h);
      }
      return { closedPeriods, openedPeriods, incomes, transfers, expenses };
    }),
  );
  return {
    ...counts,
    todo: yield* store.countTodo(userId),
    summaries: yield* summaries(userId),
  };
});

export const seen = Effect.fn("sync.seen")(function* (
  userId: UserId,
  periodId: string,
) {
  const { period } = yield* periodFor(userId, periodId);
  if (period.closedAt === null)
    return yield* new PeriodNotFound({ id: periodId });
  yield* store.markSeen(periodId, userId);
});

export const todo = Effect.fn("sync.todo")(function* (userId: UserId) {
  return (yield* store.todoFor(userId)).map(todoJson);
});

/** An item the user sees: of their wallet, or of one of their households. */
const itemFor = Effect.fn("sync.itemFor")(function* (
  userId: UserId,
  id: string,
) {
  const item = yield* store.todoById(id);
  if (item === undefined) return yield* new TodoNotFound({ id });
  if (item.userId !== null && item.userId !== userId)
    return yield* new TodoNotFound({ id });
  if (
    item.householdId !== null &&
    (yield* store.memberOf(item.householdId, userId)) === undefined
  )
    return yield* new TodoNotFound({ id });
  return item;
});

export const dismiss = Effect.fn("sync.dismiss")(function* (
  userId: UserId,
  id: string,
) {
  yield* itemFor(userId, id);
  yield* store.resolveTodo(id, userId);
});

const resolveExpense = Effect.fn("sync.resolveExpense")(function* (
  item: TodoRow,
  user: UserRow,
  payload: ResolveTodo,
) {
  if (item.householdId === null || item.ruleId === null)
    return yield* new TodoNotFound({ id: item.id });
  const { household } = yield* householdFor(
    user.id as UserId,
    item.householdId,
  );
  const rule = yield* store.ruleById(item.ruleId);
  if (rule === undefined || rule.envelopeId === null)
    return yield* new TodoNotFound({ id: item.id });
  const creator = yield* store.memberOf(household.id, rule.userId);
  // the expense is the creator's (F26) while they are a member, else the user's
  const author =
    creator === undefined
      ? user
      : { id: creator.userId, email: creator.email, name: creator.name };
  yield* inTx(
    [householdKey(household.id), walletKey(user.id)],
    Effect.gen(function* () {
      yield* addExpense(
        household,
        user,
        {
          envelopeId: rule.envelopeId ?? "",
          amountMinor: payload.amountMinor,
          spentAt: new Date(),
          title: rule.name,
          forWhom: null,
          forWhomUserId: null,
        },
        payload.decision,
        {
          author,
          ruleId: rule.id,
          occurrenceOn: item.occurrenceOn,
        },
      );
      if (item.occurrenceOn !== null)
        yield* store.setOccurrenceOutcome(rule.id, item.occurrenceOn, "done");
      yield* store.resolveTodo(item.id, user.id);
    }),
  );
});

/** Deals with an item: the decision it waits for (F34). */
export const resolve = Effect.fn("sync.resolve")(function* (
  userId: UserId,
  id: string,
  payload: ResolveTodo,
) {
  const item = yield* itemFor(userId, id);
  const user = yield* userOf(userId);
  switch (item.kind) {
    case "income_estimate": {
      if (item.refId === null) return yield* new TodoNotFound({ id });
      yield* wallet.confirmIncome(
        userId,
        item.refId,
        payload.amountMinor,
        payload.correction,
      );
      yield* store.resolveTodo(id, userId);
      return;
    }
    case "transfer_no_money": {
      if (item.ruleId === null || item.periodId === null)
        return yield* new TodoNotFound({ id });
      const period = yield* store.periodById(item.periodId);
      if (period === undefined) return yield* new TodoNotFound({ id });
      const { household } = yield* householdFor(
        userId,
        period.householdId,
      ).pipe(
        Effect.catchTag("HouseholdNotFound", () =>
          Effect.fail(new TodoNotFound({ id })),
        ),
      );
      yield* inTx(
        [householdKey(household.id), walletKey(userId)],
        Effect.gen(function* () {
          const { current } = yield* openOf(household.id);
          const target = period.closedAt === null ? period : current;
          yield* transferIn(household, target, user, payload.amountMinor);
          yield* store.resolveTodo(id, userId);
        }),
      );
      return;
    }
    case "expense_not_fit":
    case "expense_missed":
      return yield* resolveExpense(item, user, payload);
    case "expense_estimate": {
      if (item.refId === null || item.householdId === null)
        return yield* new TodoNotFound({ id });
      const expense = yield* store.expenseById(item.refId);
      if (expense === undefined) return yield* new TodoNotFound({ id });
      const { household } = yield* householdFor(userId, item.householdId);
      yield* inTx(
        [householdKey(household.id), walletKey(userId)],
        Effect.gen(function* () {
          yield* updateExpense(
            household,
            user,
            expense,
            { ...expenseInputOf(expense), amountMinor: payload.amountMinor },
            payload.decision,
            { confirmEstimate: true },
          );
          yield* store.resolveTodo(id, userId);
        }),
      );
      return;
    }
  }
  return yield* new Forbidden();
});

/** The dashboard (F38): the wallet as of today, the households over a range. */
export const overview = Effect.fn("sync.overview")(function* (
  userId: UserId,
  from: string,
  to: string,
) {
  const wallet = yield* store.walletOf(userId);
  const households = yield* Effect.forEach(
    yield* store.householdsOf(userId),
    (h) =>
      Effect.gen(function* () {
        const { current } = yield* openOf(h.id);
        const { ledger } = yield* bankOf(current);
        return {
          id: h.id,
          name: h.name,
          current: periodJson(current, current),
          balanceMinor: balanceOf(ledger),
          freeMinor: freeOf(ledger),
          spentMinor: yield* store.spentBetween(h.id, from, to),
        };
      }),
  );
  return { wallet, households, todo: yield* store.countTodo(userId) };
});
