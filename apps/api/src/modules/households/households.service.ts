import {
  type CreateHousehold,
  type Cycle as CycleJson,
  Forbidden,
  InvalidPeriodEnd,
  InvalidSchedule,
  InvalidTimeZone,
  NegativeShare,
  PeriodNotCurrent,
  type UserId,
} from "@bida/api-contract";
import { Effect } from "effect";
import type { HouseholdRow } from "../ledger/ledger.module.ts";
import {
  addDays,
  bankOf,
  type Cycle,
  createPeriod,
  cycleOf,
  DEFAULT_TIME_ZONE,
  firstPeriod,
  householdFor,
  householdJson,
  householdKey,
  inTx,
  isTimeZone,
  logChange,
  moveEnd,
  moveJson,
  nameOf,
  negativeShares,
  nextPeriod,
  openNext,
  openOf,
  ownerOf,
  periodFor,
  periodJson,
  periodSummary,
  plansExceed,
  reanchor,
  refreshPlans,
  sharesOf,
  store,
  todayIn,
  transferIn,
  walletKey,
  withdrawOut,
} from "../ledger/ledger.module.ts";

/** The envelopes a new household gets (F11). */
export const DEFAULT_ENVELOPES = [
  { name: "Jedzenie", color: "#22C55E", icon: "restaurant" },
  { name: "Mieszkanie i rachunki", color: "#3B82F6", icon: "home" },
  { name: "Transport", color: "#F59E0B", icon: "directions_car" },
  { name: "Zdrowie", color: "#EF4444", icon: "favorite" },
  { name: "Rozrywka", color: "#A855F7", icon: "movie" },
  { name: "Ubrania", color: "#EC4899", icon: "checkroom" },
  { name: "Inne", color: "#64748B", icon: "category" },
] as const;

const PALETTE = DEFAULT_ENVELOPES.map((e) => e.color);

/** The cycle of the contract, checked; monthly from the 1st by default. */
export const cycleFrom = (json: CycleJson | undefined, today: string) => {
  if (json === undefined)
    return Effect.succeed<Cycle>({ kind: "monthly", day: 1 });
  if (json.kind === "monthly")
    return json.day === null
      ? Effect.fail(new InvalidSchedule())
      : Effect.succeed<Cycle>({ kind: "monthly", day: json.day });
  if (json.kind === "weeks")
    return json.weeks === null
      ? Effect.fail(new InvalidSchedule())
      : Effect.succeed<Cycle>({
          kind: "weeks",
          weeks: json.weeks,
          anchor: json.anchorOn ?? today,
        });
  return Effect.succeed<Cycle>({ kind: "manual" });
};

export const cycleColumns = (cycle: Cycle) => ({
  cycleKind: cycle.kind,
  cycleDay: cycle.kind === "monthly" ? cycle.day : null,
  cycleWeeks: cycle.kind === "weeks" ? cycle.weeks : null,
  cycleAnchor: cycle.kind === "weeks" ? cycle.anchor : null,
});

const householdView = Effect.fn("households.view")(function* (
  userId: UserId,
  householdId: string,
) {
  const { household, member } = yield* householdFor(userId, householdId);
  return yield* householdJson(household, member);
});

export const list = Effect.fn("households.list")(function* (userId: UserId) {
  const households = yield* store.householdsOf(userId);
  return yield* Effect.forEach(households, (h) =>
    householdView(userId, h.id).pipe(Effect.orDie),
  );
});

export const get = householdView;

export const create = Effect.fn("households.create")(function* (
  userId: UserId,
  input: CreateHousehold,
) {
  const timeZone = input.timeZone ?? DEFAULT_TIME_ZONE;
  if (!isTimeZone(timeZone)) return yield* new InvalidTimeZone({ timeZone });
  const today = todayIn(timeZone);
  const cycle = yield* cycleFrom(input.cycle, today);
  if (cycle.kind === "manual" && input.firstEndsOn === undefined)
    return yield* new InvalidSchedule();
  const id = crypto.randomUUID();
  yield* inTx(
    [householdKey(id)],
    Effect.gen(function* () {
      yield* store.insertHousehold({
        id,
        name: input.name.trim(),
        timeZone,
        ...cycleColumns(cycle),
      });
      yield* store.insertMember(id, userId, "owner");
      const names = input.envelopes ?? DEFAULT_ENVELOPES.map((e) => e.name);
      const seen = new Set<string>();
      let position = 0;
      for (const raw of names) {
        const name = raw.trim();
        if (name === "" || seen.has(name.toLowerCase())) continue;
        seen.add(name.toLowerCase());
        const known = DEFAULT_ENVELOPES.find((e) => e.name === name);
        yield* store.insertEnvelope({
          id: crypto.randomUUID(),
          householdId: id,
          name,
          color:
            known?.color ?? PALETTE[position % PALETTE.length] ?? "#64748B",
          icon: known?.icon ?? null,
          position: position++,
        });
      }
      yield* createPeriod(
        id,
        firstPeriod(cycle, today, input.firstEndsOn),
        null,
      );
    }),
  );
  return yield* householdView(userId, id).pipe(Effect.orDie);
});

export const rename = Effect.fn("households.rename")(function* (
  userId: UserId,
  householdId: string,
  name: string,
) {
  yield* ownerOf(userId, householdId);
  yield* store.renameHousehold(householdId, name.trim());
  return yield* householdView(userId, householdId);
});

/**
 * Deletes a household and everything in it (F06). Not while anybody has a
 * negative share; positive shares go back to the wallets.
 */
export const removeHousehold = (h: HouseholdRow) =>
  Effect.gen(function* () {
    const negative = yield* negativeShares(h);
    if (negative.length > 0) return yield* negativeShareError(negative);
    const today = todayIn(h.timeZone);
    for (const period of yield* store.openPeriodsOf(h.id)) {
      const bank = yield* bankOf(period);
      for (const share of sharesOf(bank.ledger).people) {
        if (share.userId === null || share.shareMinor <= 0) continue;
        yield* store.insertWalletEntry({
          id: crypto.randomUUID(),
          userId: share.userId,
          kind: "return",
          amountMinor: share.shareMinor,
          onDate: today,
          householdId: h.id,
          householdName: h.name,
        });
      }
    }
    yield* store.deleteHousehold(h.id);
  });

export const negativeShareError = (
  entries: ReadonlyArray<{
    householdId: string;
    householdName: string;
    periodId: string;
    userId: string;
    shareMinor: number;
  }>,
) =>
  Effect.gen(function* () {
    const named = yield* Effect.forEach(entries, (e) =>
      Effect.map(store.userById(e.userId), (u) => ({
        ...e,
        userId: e.userId as UserId,
        name: u === undefined ? "Usunięte konto" : nameOf(u),
      })),
    );
    return yield* new NegativeShare({ entries: named });
  });

export const remove = Effect.fn("households.remove")(function* (
  userId: UserId,
  householdId: string,
) {
  const { household } = yield* ownerOf(userId, householdId);
  const members = yield* store.membersOf(householdId);
  yield* inTx(
    [householdKey(householdId), ...members.map((m) => walletKey(m.userId))],
    removeHousehold(household),
  );
});

export const setCycle = Effect.fn("households.setCycle")(function* (
  userId: UserId,
  householdId: string,
  json: CycleJson,
) {
  const { household, user } = yield* ownerOf(userId, householdId);
  const cycle = yield* cycleFrom(json, todayIn(household.timeZone));
  yield* inTx(
    [householdKey(householdId)],
    Effect.gen(function* () {
      yield* store.setHouseholdCycle(householdId, cycleColumns(cycle));
      // an open next period is recounted from the end of the current one
      const { current, next } = yield* openOf(householdId);
      if (next !== null && cycle.kind !== "manual") {
        const span = nextPeriod(cycle, current);
        yield* store.setPeriodBounds(next.id, span.startsOn, span.endsOn);
        yield* refreshPlans(householdId);
      }
      yield* logChange(
        household,
        current.id,
        user,
        "period.cycle",
        householdId,
        "Zmieniono cykl okresów",
      );
    }),
  );
  return yield* householdView(userId, householdId);
});

export const periods = Effect.fn("households.periods")(function* (
  userId: UserId,
  householdId: string,
) {
  yield* householdFor(userId, householdId);
  const { current } = yield* openOf(householdId);
  return (yield* store.periodsOf(householdId)).map((p) =>
    periodJson(p, current),
  );
});

export const openNextPeriod = Effect.fn("households.openNext")(function* (
  userId: UserId,
  householdId: string,
) {
  const { household, user } = yield* householdFor(userId, householdId);
  const period = yield* inTx(
    [householdKey(householdId)],
    openNext(household, user),
  );
  const { current } = yield* openOf(householdId);
  return periodJson(period, current);
});

export const summary = Effect.fn("households.summary")(function* (
  userId: UserId,
  periodId: string,
  forWhom?: string,
) {
  const { household, period } = yield* periodFor(userId, periodId);
  return yield* periodSummary(household, period, forWhom);
});

/** F24: not before today, and the next period keeps at least a day. */
export const setEnd = Effect.fn("households.setEnd")(function* (
  userId: UserId,
  periodId: string,
  endsOn: string,
) {
  const { household, period, member, user } = yield* periodFor(
    userId,
    periodId,
  );
  if (member.role !== "owner") return yield* new Forbidden();
  return yield* inTx(
    [householdKey(household.id)],
    Effect.gen(function* () {
      const { current, next } = yield* openOf(household.id);
      if (period.id !== current.id)
        return yield* new PeriodNotCurrent({ periodId: period.id });
      if (endsOn < todayIn(household.timeZone))
        return yield* new InvalidPeriodEnd({ reason: "beforeToday" });
      if (next !== null && endsOn >= next.endsOn)
        return yield* new InvalidPeriodEnd({ reason: "overlapsNext" });
      const cycle = reanchor(cycleOf(household), addDays(endsOn, 1));
      yield* store.setHouseholdCycle(household.id, cycleColumns(cycle));
      yield* moveEnd(household, current, next, endsOn, cycle);
      yield* logChange(
        household,
        current.id,
        user,
        "period.end",
        current.id,
        `Koniec okresu: ${current.endsOn} → ${endsOn}`,
        { endsOn: current.endsOn },
        { endsOn },
      );
      const moved = yield* store.periodById(current.id);
      if (moved === undefined) return yield* Effect.die("period vanished");
      return periodJson(moved, moved);
    }),
  );
});

export const moves = Effect.fn("households.moves")(function* (
  userId: UserId,
  periodId: string,
) {
  yield* periodFor(userId, periodId);
  return (yield* store.movesOf(periodId)).map(moveJson);
});

const moveResult = (
  period: { id: string },
  result: {
    move: store.MoveRow;
    walletMinor: number;
    usedUnconfirmed: boolean;
  },
) =>
  Effect.gen(function* () {
    const fresh = yield* store.periodById(period.id);
    return {
      move: moveJson(result.move),
      walletMinor: result.walletMinor,
      usedUnconfirmed: result.usedUnconfirmed,
      plansExceedBalance:
        fresh === undefined ? false : yield* plansExceed(fresh),
    };
  });

export const transfer = Effect.fn("households.transfer")(function* (
  userId: UserId,
  periodId: string,
  amountMinor: number,
) {
  const { household, period, user } = yield* periodFor(userId, periodId);
  return yield* inTx(
    [householdKey(household.id), walletKey(userId)],
    Effect.gen(function* () {
      const result = yield* transferIn(household, period, user, amountMinor);
      return yield* moveResult(period, result);
    }),
  );
});

export const withdraw = Effect.fn("households.withdraw")(function* (
  userId: UserId,
  periodId: string,
  amountMinor: number,
) {
  const { household, period, user } = yield* periodFor(userId, periodId);
  return yield* inTx(
    [householdKey(household.id), walletKey(userId)],
    Effect.gen(function* () {
      const result = yield* withdrawOut(household, period, user, amountMinor);
      return yield* moveResult(period, result);
    }),
  );
});
