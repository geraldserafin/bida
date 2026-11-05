import {
  type Correction,
  type CreateIncome,
  IncomeNotFound,
  PeriodNotFound,
  type UserId,
  WalletWouldGoNegative,
} from "@bida/api-contract";
import { Effect } from "effect";
import type { WalletEntryRow } from "../ledger/ledger.module.ts";
import {
  householdKey,
  inTx,
  periodFor,
  store,
  userOf,
  walletEntryJson,
  walletKey,
  withdrawOut,
} from "../ledger/ledger.module.ts";

export const get = Effect.fn("wallet.get")(function* (userId: UserId) {
  return yield* store.walletOf(userId);
});

export const entries = Effect.fn("wallet.entries")(function* (
  userId: UserId,
  limit = 50,
  offset = 0,
) {
  return (yield* store.walletEntries(userId, limit, offset)).map(
    walletEntryJson,
  );
});

const noteOf = (note: string | null) =>
  note === null || note.trim() === "" ? null : note.trim();

export const addIncome = Effect.fn("wallet.addIncome")(function* (
  userId: UserId,
  input: CreateIncome,
) {
  const id = crypto.randomUUID();
  yield* inTx(
    [walletKey(userId)],
    store.insertWalletEntry({
      id,
      userId,
      kind: "income",
      amountMinor: input.amountMinor,
      onDate: input.onDate,
      note: noteOf(input.note),
      estimated: input.estimated,
    }),
  );
  const saved = yield* store.walletEntryById(id);
  if (saved === undefined) return yield* Effect.die("income vanished");
  return walletEntryJson(saved);
});

const incomeFor = Effect.fn("wallet.incomeFor")(function* (
  userId: UserId,
  id: string,
) {
  const entry = yield* store.walletEntryById(id);
  if (entry === undefined || entry.userId !== userId || entry.kind !== "income")
    return yield* new IncomeNotFound({ id });
  return entry;
});

/** The locks a correction takes: the wallet, and the household it may withdraw from. */
const correctionKeys = Effect.fn("wallet.correctionKeys")(function* (
  userId: UserId,
  correction: Correction | null | undefined,
) {
  const keys = [walletKey(userId)];
  if (correction?.withdrawFromPeriodId != null) {
    const { household } = yield* periodFor(
      userId,
      correction.withdrawFromPeriodId,
    );
    keys.push(householdKey(household.id));
  }
  return keys;
});

/**
 * A correction down (F25): when it would put the wallet below zero, the
 * user either keeps the minus until the next income or first takes the
 * missing amount back from a period (up to their share there).
 */
const correctDown = Effect.fn("wallet.correctDown")(function* (
  userId: UserId,
  byMinor: number,
  correction: Correction | null | undefined,
) {
  if (byMinor <= 0) return;
  const wallet = yield* store.walletOf(userId);
  const after = wallet.balanceMinor - byMinor;
  if (after >= 0) return;
  const missing = -after;
  if (correction?.withdrawFromPeriodId != null) {
    const { household, period } = yield* periodFor(
      userId,
      correction.withdrawFromPeriodId,
    ).pipe(
      Effect.catchTag("PeriodNotFound", (e) =>
        Effect.fail(new PeriodNotFound(e)),
      ),
    );
    const user = yield* userOf(userId);
    // only what is still missing once the minus of before is counted
    yield* withdrawOut(household, period, user, Math.min(missing, byMinor));
    return;
  }
  if (correction?.allowNegative !== true)
    return yield* new WalletWouldGoNegative({
      walletMinor: wallet.balanceMinor,
      neededMinor: missing,
    });
});

const saved = Effect.fn("wallet.saved")(function* (id: string) {
  const entry = yield* store.walletEntryById(id);
  if (entry === undefined) return yield* Effect.die("income vanished");
  return walletEntryJson(entry);
});

export const updateIncome = Effect.fn("wallet.updateIncome")(function* (
  userId: UserId,
  id: string,
  input: {
    readonly amountMinor: number;
    readonly onDate: string;
    readonly note: string | null;
    readonly estimated: boolean;
    readonly correction?: Correction | null | undefined;
  },
) {
  yield* incomeFor(userId, id);
  const keys = yield* correctionKeys(userId, input.correction);
  yield* inTx(
    keys,
    Effect.gen(function* () {
      const entry = yield* incomeFor(userId, id);
      yield* correctDown(
        userId,
        entry.amountMinor - input.amountMinor,
        input.correction,
      );
      yield* store.updateIncome(id, {
        amountMinor: input.amountMinor,
        onDate: input.onDate,
        note: noteOf(input.note),
        estimated: input.estimated,
      });
      if (!input.estimated) yield* store.resolveTodoOfRef(id, userId);
    }),
  );
  return yield* saved(id);
});

/** The real amount of an estimated income; it is then certain. */
export const confirmIncome = Effect.fn("wallet.confirmIncome")(function* (
  userId: UserId,
  id: string,
  amountMinor: number,
  correction?: Correction | null,
) {
  const entry = yield* incomeFor(userId, id);
  return yield* updateIncome(userId, id, {
    amountMinor,
    onDate: entry.onDate,
    note: entry.note,
    estimated: false,
    correction,
  });
});

export const removeIncome = Effect.fn("wallet.removeIncome")(function* (
  userId: UserId,
  id: string,
  correction?: Correction | null,
) {
  yield* incomeFor(userId, id);
  const keys = yield* correctionKeys(userId, correction);
  yield* inTx(
    keys,
    Effect.gen(function* () {
      const entry: WalletEntryRow = yield* incomeFor(userId, id);
      yield* correctDown(userId, entry.amountMinor, correction);
      yield* store.deleteWalletEntry(id);
      yield* store.resolveTodoOfRef(id, userId);
    }),
  );
});
