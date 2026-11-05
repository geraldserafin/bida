import {
  DuplicateEnvelopeName,
  EnvelopeHasExpenses,
  EnvelopeNotFound,
  LastEnvelope,
  type SaveEnvelope,
  type UserId,
} from "@bida/api-contract";
import { Effect } from "effect";
import type {
  EnvelopeRow,
  HouseholdRow,
  UserRow,
} from "../ledger/ledger.module.ts";
import {
  bankOf,
  envelopeJson,
  householdFor,
  householdKey,
  inTx,
  logChange,
  openOf,
  periodFor,
  periodSummary,
  refreshPlans,
  setPlanTotal,
  spentFrom,
  store,
} from "../ledger/ledger.module.ts";

export const list = Effect.fn("envelopes.list")(function* (
  userId: UserId,
  householdId: string,
) {
  yield* householdFor(userId, householdId);
  return (yield* store.envelopesOf(householdId)).map(envelopeJson);
});

const uniqueName = Effect.fn("envelopes.uniqueName")(function* (
  householdId: string,
  name: string,
  exceptId?: string,
) {
  const taken = yield* store.envelopeNamed(householdId, name);
  if (taken !== undefined && taken.id !== exceptId)
    return yield* new DuplicateEnvelopeName({ name });
});

/** Any member of the household (F12); every change goes to the log. */
const envelopeFor = Effect.fn("envelopes.envelopeFor")(function* (
  userId: UserId,
  envelopeId: string,
) {
  const envelope = yield* store.envelopeById(envelopeId);
  if (envelope === undefined)
    return yield* new EnvelopeNotFound({ id: envelopeId });
  const found = yield* householdFor(userId, envelope.householdId).pipe(
    Effect.catchTag("HouseholdNotFound", () =>
      Effect.fail(new EnvelopeNotFound({ id: envelopeId })),
    ),
  );
  return { ...found, envelope };
});

const log = Effect.fn("envelopes.log")(function* (
  h: HouseholdRow,
  user: UserRow,
  action: string,
  envelope: EnvelopeRow,
  summary: string,
  before: unknown = null,
  after: unknown = null,
) {
  const { current } = yield* openOf(h.id);
  yield* logChange(
    h,
    current.id,
    user,
    action,
    envelope.id,
    summary,
    before,
    after,
  );
});

export const create = Effect.fn("envelopes.create")(function* (
  userId: UserId,
  householdId: string,
  input: SaveEnvelope,
) {
  const { household, user } = yield* householdFor(userId, householdId);
  const name = input.name.trim();
  return yield* inTx(
    [householdKey(householdId)],
    Effect.gen(function* () {
      yield* uniqueName(householdId, name);
      const all = yield* store.envelopesOf(householdId);
      const id = crypto.randomUUID();
      yield* store.insertEnvelope({
        id,
        householdId,
        name,
        color: input.color,
        icon: input.icon,
        position: all.reduce((max, e) => Math.max(max, e.position + 1), 0),
      });
      const envelope = yield* store.envelopeById(id);
      if (envelope === undefined) return yield* Effect.die("envelope vanished");
      yield* refreshPlans(householdId);
      yield* log(
        household,
        user,
        "envelope.create",
        envelope,
        `Nowa koperta „${name}”`,
      );
      return envelopeJson(envelope);
    }),
  );
});

export const update = Effect.fn("envelopes.update")(function* (
  userId: UserId,
  envelopeId: string,
  input: SaveEnvelope,
) {
  const { household, user, envelope } = yield* envelopeFor(userId, envelopeId);
  const name = input.name.trim();
  return yield* inTx(
    [householdKey(household.id)],
    Effect.gen(function* () {
      yield* uniqueName(household.id, name, envelopeId);
      yield* store.updateEnvelope(envelopeId, { ...input, name });
      yield* log(
        household,
        user,
        "envelope.update",
        envelope,
        `Koperta „${envelope.name}” → „${name}”`,
        { name: envelope.name, color: envelope.color, icon: envelope.icon },
        { name, color: input.color, icon: input.icon },
      );
      const saved = yield* store.envelopeById(envelopeId);
      if (saved === undefined) return yield* Effect.die("envelope vanished");
      return envelopeJson(saved);
    }),
  );
});

const lastActive = Effect.fn("envelopes.lastActive")(function* (
  h: HouseholdRow,
  envelope: EnvelopeRow,
) {
  const active = (yield* store.envelopesOf(h.id)).filter(
    (e) => e.archivedAt === null,
  );
  if (envelope.archivedAt === null && active.length <= 1)
    return yield* new LastEnvelope();
});

/** Only an envelope without expenses goes; the others are archived. */
export const remove = Effect.fn("envelopes.remove")(function* (
  userId: UserId,
  envelopeId: string,
) {
  const { household, user, envelope } = yield* envelopeFor(userId, envelopeId);
  yield* inTx(
    [householdKey(household.id)],
    Effect.gen(function* () {
      if (yield* store.envelopeHasExpenses(envelopeId))
        return yield* new EnvelopeHasExpenses({ id: envelopeId });
      yield* lastActive(household, envelope);
      const plans: Array<store.PlanRow> = [];
      for (const period of yield* store.openPeriodsOf(household.id))
        plans.push(
          ...(yield* store.plansOf(period.id)).filter(
            (p) => p.envelopeId === envelopeId,
          ),
        );
      yield* log(
        household,
        user,
        "envelope.delete",
        envelope,
        `Usunięto kopertę „${envelope.name}”`,
        { envelope, plans },
      );
      yield* store.deleteEnvelope(envelopeId);
    }),
  );
});

/**
 * Archiving keeps the expenses; the plans in the open periods drop to what
 * was spent, so the money they held is free again.
 */
export const archive = Effect.fn("envelopes.archive")(function* (
  userId: UserId,
  envelopeId: string,
  archived: boolean,
) {
  const { household, user, envelope } = yield* envelopeFor(userId, envelopeId);
  return yield* inTx(
    [householdKey(household.id)],
    Effect.gen(function* () {
      if (archived) {
        yield* lastActive(household, envelope);
        for (const period of yield* store.openPeriodsOf(household.id)) {
          const bank = yield* bankOf(period);
          const row = bank.plans.find((p) => p.envelopeId === envelopeId);
          if (row === undefined) continue;
          const spent = spentFrom(bank.ledger, envelopeId);
          yield* store.upsertPlan({
            ...row,
            manualMinor: spent - row.recurringMinor,
          });
        }
      }
      yield* store.setArchived(envelopeId, archived);
      yield* log(
        household,
        user,
        archived ? "envelope.archive" : "envelope.unarchive",
        envelope,
        `${archived ? "Zarchiwizowano" : "Przywrócono"} kopertę „${envelope.name}”`,
      );
      const saved = yield* store.envelopeById(envelopeId);
      if (saved === undefined) return yield* Effect.die("envelope vanished");
      return envelopeJson(saved);
    }),
  );
});

/** F19: any member, in an open period, not below what was spent. */
export const setPlan = Effect.fn("envelopes.setPlan")(function* (
  userId: UserId,
  periodId: string,
  envelopeId: string,
  amountMinor: number,
) {
  const { household, period, user } = yield* periodFor(userId, periodId);
  yield* inTx(
    [householdKey(household.id)],
    setPlanTotal(household, period, envelopeId, amountMinor, user),
  );
  return yield* periodSummary(household, period);
});
