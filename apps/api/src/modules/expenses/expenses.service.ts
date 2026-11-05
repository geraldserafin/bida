import {
  ExpenseNotFound,
  type SaveExpense,
  type UserId,
} from "@bida/api-contract";
import { DateTime, Effect } from "effect";
import {
  addExpense,
  deleteExpense,
  type ExpenseInput,
  expenseJson,
  householdFor,
  householdKey,
  inTx,
  store,
  updateExpense,
  walletKey,
} from "../ledger/ledger.module.ts";

const DEFAULT_LIMIT = 50;

export const inputOf = (payload: SaveExpense): ExpenseInput => ({
  envelopeId: payload.envelopeId,
  amountMinor: payload.amountMinor,
  spentAt: DateTime.toDateUtc(payload.spentAt),
  title:
    payload.title === null || payload.title.trim() === ""
      ? null
      : payload.title.trim(),
  forWhom: payload.forWhom,
  forWhomUserId: payload.forWhom === "member" ? payload.forWhomUserId : null,
});

type Result = {
  expense: store.ExpenseRow;
  transferredMinor: number;
  raisedPlanMinor: number;
  plansExceedBalance: boolean;
};

export const resultJson = (result: Result) => ({
  ...result,
  expense: expenseJson(result.expense),
});

/** F08: it has to fit the plan and the balance, or the user decides. */
export const create = Effect.fn("expenses.create")(function* (
  userId: UserId,
  householdId: string,
  payload: SaveExpense,
) {
  const { household, user } = yield* householdFor(userId, householdId);
  const result = yield* inTx(
    [householdKey(householdId), walletKey(userId)],
    addExpense(household, user, inputOf(payload), payload.decision),
  );
  return resultJson(result);
});

const expenseFor = Effect.fn("expenses.expenseFor")(function* (
  userId: UserId,
  id: string,
) {
  const expense = yield* store.expenseById(id);
  if (expense === undefined) return yield* new ExpenseNotFound({ id });
  const found = yield* householdFor(userId, expense.householdId).pipe(
    Effect.catchTag("HouseholdNotFound", () =>
      Effect.fail(new ExpenseNotFound({ id })),
    ),
  );
  return { ...found, expense };
});

export const get = Effect.fn("expenses.get")(function* (
  userId: UserId,
  id: string,
) {
  return expenseJson((yield* expenseFor(userId, id)).expense);
});

export const update = Effect.fn("expenses.update")(function* (
  userId: UserId,
  id: string,
  payload: SaveExpense,
) {
  const { household, user, expense } = yield* expenseFor(userId, id);
  const result = yield* inTx(
    [householdKey(household.id), walletKey(userId)],
    updateExpense(household, user, expense, inputOf(payload), payload.decision),
  );
  return resultJson(result);
});

export const remove = Effect.fn("expenses.remove")(function* (
  userId: UserId,
  id: string,
) {
  const { household, user, expense } = yield* expenseFor(userId, id);
  yield* inTx(
    [householdKey(household.id)],
    deleteExpense(household, user, expense),
  );
});

export interface ListExpenses {
  readonly householdId?: string | undefined;
  readonly periodId?: string | undefined;
  readonly envelopeId?: string | undefined;
  readonly authorId?: string | undefined;
  readonly forWhom?: string | undefined;
  readonly from?: string | undefined;
  readonly to?: string | undefined;
  readonly limit?: number | undefined;
  readonly offset?: number | undefined;
}

/** F10: newest first, over the user's households. */
export const list = Effect.fn("expenses.list")(function* (
  userId: UserId,
  filter: ListExpenses,
) {
  const mine = (yield* store.householdsOf(userId)).map((h) => h.id);
  const householdIds =
    filter.householdId === undefined
      ? mine
      : mine.filter((id) => id === filter.householdId);
  const rows = yield* store.listExpenses({
    householdIds,
    periodId: filter.periodId,
    envelopeId: filter.envelopeId,
    authorId: filter.authorId,
    forWhom: filter.forWhom,
    from: filter.from,
    to: filter.to,
    limit: filter.limit ?? DEFAULT_LIMIT,
    offset: filter.offset ?? 0,
  });
  return rows.map(expenseJson);
});
