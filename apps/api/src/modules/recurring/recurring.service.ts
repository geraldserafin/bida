import {
  EnvelopeNotFound,
  Forbidden,
  HouseholdNotFound,
  InvalidSchedule,
  RuleNotFound,
  type SaveRule,
  type UserId,
} from "@bida/api-contract";
import { Effect } from "effect";
import type { RuleFields, RuleRow } from "../ledger/ledger.module.ts";
import {
  addDays,
  householdFor,
  householdKey,
  instantOn,
  inTx,
  openOf,
  refreshPlans,
  ruleJson,
  store,
  todayIn,
  userOf,
  walletKey,
} from "../ledger/ledger.module.ts";
import {
  addRuleIncome,
  linkedKeys,
  pendingDays,
  runExpense,
  runTransfer,
  walletToday,
} from "./engine.ts";

export const list = Effect.fn("recurring.list")(function* (userId: UserId) {
  return (yield* store.rulesVisibleTo(userId)).map((r) => ({
    ...ruleJson(r),
  }));
});

/** Checks a rule against the household and envelope it names. */
const fieldsOf = Effect.fn("recurring.fieldsOf")(function* (
  userId: UserId,
  input: SaveRule,
) {
  if (input.frequency === "monthly" && input.dayOfMonth === null)
    return yield* new InvalidSchedule();
  if (input.frequency === "weeks" && input.everyWeeks === null)
    return yield* new InvalidSchedule();
  if (input.kind === "transfer" && input.target === null)
    return yield* new InvalidSchedule();
  // a transfer that follows an income takes its amount and schedule
  const incomeRuleId =
    input.kind === "transfer" ? (input.incomeRuleId ?? null) : null;
  const income =
    incomeRuleId === null ? undefined : yield* store.ruleById(incomeRuleId);
  if (
    incomeRuleId !== null &&
    (income === undefined ||
      income.kind !== "income" ||
      income.userId !== userId)
  )
    return yield* new RuleNotFound({ id: incomeRuleId });
  let householdId: string | null = null;
  let envelopeId: string | null = null;
  let today = walletToday();
  if (input.kind !== "income") {
    if (input.householdId === null)
      return yield* new HouseholdNotFound({ id: "" });
    const { household } = yield* householdFor(userId, input.householdId);
    householdId = household.id;
    today = todayIn(household.timeZone);
  }
  if (input.kind === "expense") {
    const envelope =
      input.envelopeId === null
        ? undefined
        : yield* store.envelopeById(input.envelopeId);
    if (envelope === undefined || envelope.householdId !== householdId)
      return yield* new EnvelopeNotFound({ id: input.envelopeId ?? "" });
    envelopeId = envelope.id;
  }
  if (income !== undefined)
    return {
      kind: input.kind,
      userId,
      householdId,
      envelopeId,
      name: input.name.trim(),
      amountMinor: income.amountMinor,
      estimated: false,
      frequency: income.frequency,
      dayOfMonth: income.dayOfMonth,
      everyWeeks: income.everyWeeks,
      anchorOn: income.anchorOn,
      startsOn: income.startsOn,
      target: input.target,
      incomeRuleId: income.id,
      active: input.active,
    } satisfies RuleFields;
  const startsOn = input.startsOn ?? today;
  return {
    kind: input.kind,
    userId,
    householdId,
    envelopeId,
    name: input.name.trim(),
    amountMinor: input.amountMinor,
    // a transfer moves a known amount; only incomes and expenses are estimated
    estimated: input.kind === "transfer" ? false : input.estimated,
    frequency: input.frequency,
    dayOfMonth: input.frequency === "monthly" ? input.dayOfMonth : null,
    everyWeeks: input.frequency === "weeks" ? input.everyWeeks : null,
    anchorOn: input.frequency === "weeks" ? (input.anchorOn ?? startsOn) : null,
    startsOn,
    target: input.kind === "transfer" ? input.target : null,
    incomeRuleId: null,
    active: input.active,
  } satisfies RuleFields;
});

/** Income and transfer rules are their owner's; expense rules: the author or an owner. */
const ruleFor = Effect.fn("recurring.ruleFor")(function* (
  userId: UserId,
  id: string,
  change: boolean,
) {
  const rule = yield* store.ruleById(id);
  if (rule === undefined) return yield* new RuleNotFound({ id });
  if (rule.kind !== "expense") {
    if (rule.userId !== userId) return yield* new RuleNotFound({ id });
    return rule;
  }
  const member =
    rule.householdId === null
      ? undefined
      : yield* store.memberOf(rule.householdId, userId);
  if (member === undefined) return yield* new RuleNotFound({ id });
  if (change && rule.userId !== userId && member.role !== "owner")
    return yield* new Forbidden();
  return rule;
});

const keysOf = (fields: { householdId: string | null }, userId: string) =>
  fields.householdId === null
    ? [walletKey(userId)]
    : [walletKey(userId), householdKey(fields.householdId)];

export const create = Effect.fn("recurring.create")(function* (
  userId: UserId,
  input: SaveRule,
) {
  const fields = yield* fieldsOf(userId, input);
  const id = crypto.randomUUID();
  yield* inTx(
    keysOf(fields, userId),
    Effect.gen(function* () {
      yield* store.insertRule(id, fields);
      if (fields.householdId !== null) yield* refreshPlans(fields.householdId);
    }),
  );
  const saved = yield* store.ruleById(id);
  if (saved === undefined) return yield* Effect.die("rule vanished");
  return ruleJson(saved);
});

export const update = Effect.fn("recurring.update")(function* (
  userId: UserId,
  id: string,
  input: SaveRule,
) {
  const rule = yield* ruleFor(userId, id, true);
  // the author stays who made it
  const fields = {
    ...(yield* fieldsOf(userId, input)),
    kind: rule.kind,
    userId: rule.userId,
  };
  yield* inTx(
    [
      ...keysOf(fields, userId),
      ...(rule.householdId === null ? [] : [householdKey(rule.householdId)]),
    ],
    Effect.gen(function* () {
      yield* store.updateRule(id, fields);
      if (rule.householdId !== null) yield* refreshPlans(rule.householdId);
      if (
        fields.householdId !== null &&
        fields.householdId !== rule.householdId
      )
        yield* refreshPlans(fields.householdId);
    }),
  );
  const saved = yield* store.ruleById(id);
  if (saved === undefined) return yield* Effect.die("rule vanished");
  return ruleJson(saved);
});

/** What the rule made stays. */
export const remove = Effect.fn("recurring.remove")(function* (
  userId: UserId,
  id: string,
) {
  const rule = yield* ruleFor(userId, id, true);
  yield* inTx(
    keysOf(rule, userId),
    Effect.gen(function* () {
      yield* store.deleteRule(id);
      if (rule.householdId !== null) yield* refreshPlans(rule.householdId);
    }),
  );
});

/** The next occurrence not dealt with yet, within a year. */
const nextDay = Effect.fn("recurring.nextDay")(function* (
  rule: RuleRow,
  from: string,
  to: string,
) {
  return (yield* pendingDays(rule, to, from))[0];
});

/** Applies a rule early (F25, F26): its next occurrence, now. */
export const apply = Effect.fn("recurring.apply")(function* (
  userId: UserId,
  id: string,
  amountMinor: number | null,
) {
  const rule = yield* ruleFor(userId, id, false);
  const user = yield* userOf(userId);
  // it goes when its income goes
  if (rule.incomeRuleId !== null) return { applied: 0, todo: 0 };
  return yield* inTx(
    [
      ...keysOf(rule, userId),
      ...(rule.kind === "income" ? yield* linkedKeys(rule.id) : []),
    ],
    Effect.gen(function* () {
      if (rule.kind === "income") {
        const today = walletToday();
        const day = yield* nextDay(rule, rule.startsOn, addDays(today, 400));
        if (day === undefined) return { applied: 0, todo: 0 };
        const estimated = rule.estimated && amountMinor === null;
        yield* addRuleIncome(
          rule,
          day,
          amountMinor ?? rule.amountMinor,
          estimated,
        );
        return { applied: 1, todo: 0 };
      }
      if (rule.householdId === null) return { applied: 0, todo: 0 };
      const h = yield* store.householdById(rule.householdId);
      if (h === undefined) return { applied: 0, todo: 0 };
      if (rule.kind === "transfer") {
        const day = yield* nextDay(
          rule,
          rule.startsOn,
          addDays(todayIn(h.timeZone), 400),
        );
        if (day === undefined) return { applied: 0, todo: 0 };
        const outcome = yield* runTransfer(
          rule,
          user,
          day,
          amountMinor ?? rule.amountMinor,
        );
        return outcome === "done"
          ? { applied: 1, todo: 0 }
          : { applied: 0, todo: 1 };
      }
      const { current } = yield* openOf(h.id);
      const day = yield* nextDay(rule, current.startsOn, current.endsOn);
      if (day === undefined) return { applied: 0, todo: 0 };
      const spentAt =
        day <= todayIn(h.timeZone) ? instantOn(day, h.timeZone) : new Date();
      const outcome = yield* runExpense(
        h,
        amountMinor === null
          ? rule
          : { ...rule, amountMinor, estimated: false },
        day,
        spentAt,
      );
      return outcome === "done"
        ? { applied: 1, todo: 0 }
        : { applied: 0, todo: 1 };
    }),
  );
});

/** Every expense rule of a household, for what is left of the current period. */
export const applyAll = Effect.fn("recurring.applyAll")(function* (
  userId: UserId,
  householdId: string,
) {
  const { household } = yield* householdFor(userId, householdId);
  return yield* inTx(
    [householdKey(householdId)],
    Effect.gen(function* () {
      const { current } = yield* openOf(householdId);
      const today = todayIn(household.timeZone);
      let applied = 0;
      let todo = 0;
      for (const rule of yield* store.activeExpenseRulesOf(householdId))
        for (const day of yield* pendingDays(
          rule,
          current.endsOn,
          current.startsOn,
        )) {
          const spentAt =
            day <= today ? instantOn(day, household.timeZone) : new Date();
          const outcome = yield* runExpense(household, rule, day, spentAt);
          if (outcome === "done") applied++;
          if (outcome === "todo") todo++;
        }
      return { applied, todo };
    }),
  );
});
