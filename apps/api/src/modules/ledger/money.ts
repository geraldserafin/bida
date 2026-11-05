// The arithmetic of a piggy bank (one period of a household), with no
// database in sight: WO08, F16, F19, F33 and the steps of F08.

export type MoveKind = "transfer" | "withdrawal" | "carry" | "forfeit";

export interface Move {
  /** Null for nobody's money (what the period before left). */
  readonly userId: string | null;
  readonly kind: MoveKind;
  readonly amountMinor: number;
}

export interface SpentItem {
  readonly id: string;
  /** Null when the author's account is gone. */
  readonly userId: string | null;
  readonly envelopeId: string;
  readonly amountMinor: number;
  /** When it was spent, then when it was written down: the order of F33. */
  readonly spentAtMs: number;
  readonly createdAtMs: number;
}

export interface PlanRow {
  readonly envelopeId: string;
  readonly manualMinor: number;
  readonly recurringMinor: number;
}

export interface Ledger {
  readonly moves: ReadonlyArray<Move>;
  readonly expenses: ReadonlyArray<SpentItem>;
  readonly plans: ReadonlyArray<PlanRow>;
}

const sum = (values: Iterable<number>) => {
  let total = 0;
  for (const v of values) total += v;
  return total;
};

const ofKind = (ledger: Ledger, kind: MoveKind) =>
  sum(ledger.moves.filter((m) => m.kind === kind).map((m) => m.amountMinor));

export const transfersOf = (ledger: Ledger) => ofKind(ledger, "transfer");
export const withdrawalsOf = (ledger: Ledger) => ofKind(ledger, "withdrawal");
export const carryOf = (ledger: Ledger) => ofKind(ledger, "carry");
export const spentOf = (ledger: Ledger) =>
  sum(ledger.expenses.map((e) => e.amountMinor));

/** Saldo skarbonki = przelewy − wycofania + niewydane z poprzedniego okresu − wydatki. */
export const balanceOf = (ledger: Ledger) =>
  transfersOf(ledger) -
  withdrawalsOf(ledger) +
  carryOf(ledger) -
  spentOf(ledger);

export const planOf = (ledger: Ledger, envelopeId: string) => {
  const row = ledger.plans.find((p) => p.envelopeId === envelopeId);
  return row === undefined ? 0 : row.manualMinor + row.recurringMinor;
};

export const spentFrom = (ledger: Ledger, envelopeId: string) =>
  sum(
    ledger.expenses
      .filter((e) => e.envelopeId === envelopeId)
      .map((e) => e.amountMinor),
  );

/** What the plans still hold: per envelope its plan less what was spent, never below zero. */
export const remainingPlansOf = (ledger: Ledger) => {
  const envelopes = new Set([
    ...ledger.plans.map((p) => p.envelopeId),
    ...ledger.expenses.map((e) => e.envelopeId),
  ]);
  return sum(
    [...envelopes].map((id) =>
      Math.max(planOf(ledger, id) - spentFrom(ledger, id), 0),
    ),
  );
};

export const plansTotalOf = (ledger: Ledger) =>
  sum(ledger.plans.map((p) => p.manualMinor + p.recurringMinor));

/** Wolne pieniądze = saldo − pozostała część planów. Negative: the plans exceed the balance. */
export const freeOf = (ledger: Ledger) =>
  balanceOf(ledger) - remainingPlansOf(ledger);

export interface Share {
  readonly userId: string | null;
  readonly transfersMinor: number;
  readonly withdrawalsMinor: number;
  /** What they gave up to nobody (they left). */
  readonly forfeitedMinor: number;
  /** All they spent, and of it what came out of nobody's money. */
  readonly spentMinor: number;
  readonly fromNobodyMinor: number;
  /** przelewy − wycofania − wydatki ponad pieniądze niczyje. */
  readonly shareMinor: number;
}

export interface Shares {
  readonly people: ReadonlyArray<Share>;
  /** Nobody's money that is still there. */
  readonly nobodyLeftMinor: number;
  readonly nobodyMinor: number;
}

/**
 * Who has how much in the piggy bank (F33). Nobody's money (the carry from
 * the period before and what people gave up) pays for the expenses first, in
 * the order they were spent; the rest comes out of the share of the author.
 */
export const sharesOf = (ledger: Ledger): Shares => {
  const nobodyMinor = carryOf(ledger) + ofKind(ledger, "forfeit");
  const people = new Map<
    string | null,
    {
      transfers: number;
      withdrawals: number;
      forfeited: number;
      spent: number;
      fromNobody: number;
    }
  >();
  const of = (userId: string | null) => {
    let found = people.get(userId);
    if (found === undefined) {
      found = {
        transfers: 0,
        withdrawals: 0,
        forfeited: 0,
        spent: 0,
        fromNobody: 0,
      };
      people.set(userId, found);
    }
    return found;
  };
  for (const move of ledger.moves) {
    if (move.kind === "carry") continue;
    const person = of(move.userId);
    if (move.kind === "transfer") person.transfers += move.amountMinor;
    if (move.kind === "withdrawal") person.withdrawals += move.amountMinor;
    if (move.kind === "forfeit") person.forfeited += move.amountMinor;
  }
  let nobodyLeft = nobodyMinor;
  const ordered = [...ledger.expenses].sort(
    (a, b) =>
      a.spentAtMs - b.spentAtMs ||
      a.createdAtMs - b.createdAtMs ||
      (a.id < b.id ? -1 : a.id > b.id ? 1 : 0),
  );
  for (const expense of ordered) {
    const person = of(expense.userId);
    const fromNobody = Math.min(nobodyLeft, expense.amountMinor);
    nobodyLeft -= fromNobody;
    person.spent += expense.amountMinor;
    person.fromNobody += fromNobody;
  }
  return {
    nobodyMinor,
    nobodyLeftMinor: nobodyLeft,
    people: [...people].map(([userId, p]) => ({
      userId,
      transfersMinor: p.transfers,
      withdrawalsMinor: p.withdrawals,
      forfeitedMinor: p.forfeited,
      spentMinor: p.spent,
      fromNobodyMinor: p.fromNobody,
      shareMinor:
        p.transfers - p.withdrawals - p.forfeited - (p.spent - p.fromNobody),
    })),
  };
};

export const shareOf = (ledger: Ledger, userId: string) =>
  sharesOf(ledger).people.find((p) => p.userId === userId)?.shareMinor ?? 0;

/** At most their share, and at most what is physically in the piggy bank (F32). */
export const withdrawableOf = (ledger: Ledger, userId: string) =>
  Math.max(0, Math.min(shareOf(ledger, userId), balanceOf(ledger)));

export interface ExpenseRequest {
  readonly envelopeId: string;
  readonly amountMinor: number;
  /** The expense being edited: left out of the numbers it is checked against. */
  readonly replacingId?: string | undefined;
}

export interface Resolution {
  /** The user agreed to raise the plan though there is no free money for it. */
  readonly raisePlan: boolean;
  /** Put this much from the wallet of the user into the period first. */
  readonly transferMinor: number;
}

/**
 * How an expense fits (F08): `fits` as it is; `raise` the plan by the
 * shortfall out of free money, on its own (step 1); or it `needs` the user:
 * the plan is too small and there is no free money for it (step 2), or the
 * piggy bank has less than the expense. `transferMinor` is what to bring
 * from the wallet so that the plan can be raised out of free money and the
 * balance holds the expense.
 */
export type Fit =
  | { readonly kind: "fits" }
  | { readonly kind: "raise"; readonly raiseMinor: number }
  | {
      readonly kind: "needs";
      /** By how much the plan is too small (0: the plan is fine, the balance is not). */
      readonly planShortMinor: number;
      readonly freeMinor: number;
      readonly balanceMinor: number;
      readonly transferMinor: number;
    };

const without = (ledger: Ledger, id: string | undefined): Ledger =>
  id === undefined
    ? ledger
    : { ...ledger, expenses: ledger.expenses.filter((e) => e.id !== id) };

export const fitOf = (ledger: Ledger, request: ExpenseRequest): Fit => {
  const rest = without(ledger, request.replacingId);
  const balance = balanceOf(rest);
  const free = freeOf(rest);
  const short =
    spentFrom(rest, request.envelopeId) +
    request.amountMinor -
    planOf(rest, request.envelopeId);
  if (short <= 0) {
    if (balance >= request.amountMinor) return { kind: "fits" };
    return {
      kind: "needs",
      planShortMinor: 0,
      freeMinor: free,
      balanceMinor: balance,
      transferMinor: request.amountMinor - balance,
    };
  }
  // the plan holds less than the expense: free money covers the gap, and
  // then the balance holds the expense too
  if (free >= short) return { kind: "raise", raiseMinor: short };
  return {
    kind: "needs",
    planShortMinor: short,
    freeMinor: free,
    balanceMinor: balance,
    transferMinor: Math.max(
      short - Math.max(free, 0),
      request.amountMinor - balance,
      0,
    ),
  };
};

/**
 * Whether the expense goes in with what the user decided: the transfer is
 * counted in, a plan that is still too small needs `raisePlan`, and the
 * balance must hold the expense. Returns by how much to raise the plan.
 */
export const settle = (
  ledger: Ledger,
  request: ExpenseRequest,
  resolution: Resolution,
):
  | { readonly ok: true; readonly raiseMinor: number }
  | { readonly ok: false } => {
  const funded: Ledger =
    resolution.transferMinor > 0
      ? {
          ...ledger,
          moves: [
            ...ledger.moves,
            {
              userId: null,
              kind: "transfer",
              amountMinor: resolution.transferMinor,
            },
          ],
        }
      : ledger;
  const fit = fitOf(funded, request);
  if (fit.kind === "fits") return { ok: true, raiseMinor: 0 };
  if (fit.kind === "raise") return { ok: true, raiseMinor: fit.raiseMinor };
  if (
    resolution.raisePlan &&
    fit.balanceMinor >= request.amountMinor &&
    fit.planShortMinor > 0
  )
    return { ok: true, raiseMinor: fit.planShortMinor };
  return { ok: false };
};
