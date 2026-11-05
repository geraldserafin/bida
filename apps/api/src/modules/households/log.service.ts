import {
  CannotUndo,
  DuplicateEnvelopeName,
  Forbidden,
  type LogEntry,
  LogEntryNotFound,
  NotEnoughMoney,
  type UserId,
} from "@bida/api-contract";
import { Effect } from "effect";
import type {
  HouseholdRow,
  LogRow,
  MemberRow,
  UserRow,
} from "../ledger/ledger.module.ts";
import {
  addExpense,
  bankOf,
  deleteExpense,
  type ExpenseInput,
  householdFor,
  householdKey,
  inTx,
  setPlanTotal,
  store,
  updateExpense,
  utc,
  walletKey,
  withdrawableOf,
} from "../ledger/ledger.module.ts";
import { setEnd } from "./households.service.ts";

/** What can be undone, and who may: the person who did it, an owner, or any member. */
const UNDOABLE: Record<string, "self" | "selfOrOwner" | "owner" | "member"> = {
  "expense.create": "selfOrOwner",
  "expense.update": "selfOrOwner",
  "expense.delete": "selfOrOwner",
  "plan.set": "member",
  transfer: "self",
  withdrawal: "self",
  "envelope.create": "member",
  "envelope.update": "member",
  "envelope.archive": "member",
  "envelope.unarchive": "member",
  "envelope.delete": "member",
  "period.end": "owner",
};

const mayUndo = (entry: LogRow, member: MemberRow) => {
  const who = UNDOABLE[entry.action];
  if (who === undefined || entry.undoneAt !== null) return false;
  const self = entry.userId === member.userId;
  if (who === "self") return self;
  if (who === "selfOrOwner") return self || member.role === "owner";
  if (who === "owner") return member.role === "owner";
  return true;
};

export const list = Effect.fn("log.list")(function* (
  userId: UserId,
  householdId: string,
) {
  const { member } = yield* householdFor(userId, householdId);
  return (yield* store.logOf(householdId)).map(
    (e): LogEntry => ({
      id: e.id,
      householdId: e.householdId,
      periodId: e.periodId,
      userId: e.userId as UserId | null,
      userName: e.userName,
      action: e.action,
      summary: e.summary,
      createdAt: utc(e.createdAt),
      undone: e.undoneAt !== null,
      canUndo: mayUndo(e, member),
    }),
  );
});

/** Errors an undo does not report as they are: the change cannot be undone. */
const refuse = (error: { readonly _tag: string }) =>
  Effect.fail(new CannotUndo({ reason: error._tag }));

type Before = Record<string, unknown>;

const inputFrom = (before: Before): ExpenseInput => ({
  envelopeId: String(before.envelopeId),
  amountMinor: Number(before.amountMinor),
  spentAt: new Date(String(before.spentAt)),
  title: (before.title as string | null) ?? null,
  forWhom: (before.forWhom as "member" | "shared" | null) ?? null,
  forWhomUserId: (before.forWhomUserId as string | null) ?? null,
});

const gone = (what: string) =>
  new CannotUndo({ reason: `${what} już nie istnieje` });

const undoEntry = (h: HouseholdRow, user: UserRow, entry: LogRow) =>
  Effect.gen(function* () {
    const before = (entry.before ?? {}) as Before;
    switch (entry.action) {
      case "expense.create": {
        const expense = yield* store.expenseById(entry.entityId);
        if (expense === undefined) return yield* gone("Wydatek");
        return yield* deleteExpense(h, user, expense, { quiet: true });
      }
      case "expense.update": {
        const expense = yield* store.expenseById(entry.entityId);
        if (expense === undefined) return yield* gone("Wydatek");
        yield* updateExpense(h, user, expense, inputFrom(before), undefined, {
          quiet: true,
        });
        return;
      }
      case "expense.delete": {
        if ((yield* store.expenseById(entry.entityId)) !== undefined)
          return yield* new CannotUndo({ reason: "Wydatek już jest" });
        const creatorId = (before.createdBy as string | null) ?? null;
        const creator =
          creatorId === null
            ? undefined
            : yield* store.memberOf(h.id, creatorId);
        yield* addExpense(h, user, inputFrom(before), undefined, {
          id: entry.entityId,
          author:
            creator === undefined
              ? user
              : {
                  id: creator.userId,
                  email: creator.email,
                  name: creator.name,
                },
          estimated: before.estimated === true,
          quiet: true,
        });
        return;
      }
      case "plan.set": {
        const period = yield* store.periodById(String(before.periodId));
        if (period === undefined) return yield* gone("Okres");
        return yield* setPlanTotal(
          h,
          period,
          String(before.envelopeId),
          Number(before.totalMinor),
          user,
        );
      }
      case "transfer":
      case "withdrawal": {
        const move = yield* store.moveById(entry.entityId);
        if (move === undefined) return yield* gone("Przelew");
        const period = yield* store.periodById(move.periodId);
        if (period === undefined || period.closedAt !== null)
          return yield* gone("Okres");
        if (entry.action === "transfer") {
          const bank = yield* bankOf(period);
          const available = withdrawableOf(bank.ledger, user.id);
          if (move.amountMinor > available)
            return yield* new NotEnoughMoney({ availableMinor: available });
        } else {
          const wallet = yield* store.walletOf(user.id);
          if (move.amountMinor > wallet.balanceMinor)
            return yield* new NotEnoughMoney({
              availableMinor: wallet.balanceMinor,
            });
        }
        const walletEntry = yield* store.walletEntryOfMove(move.id);
        if (walletEntry !== undefined)
          yield* store.deleteWalletEntry(walletEntry.id);
        return yield* store.deleteMove(move.id);
      }
      case "envelope.create": {
        const envelope = yield* store.envelopeById(entry.entityId);
        if (envelope === undefined) return yield* gone("Koperta");
        if (yield* store.envelopeHasExpenses(envelope.id))
          return yield* new CannotUndo({ reason: "Koperta ma wydatki" });
        return yield* store.deleteEnvelope(envelope.id);
      }
      case "envelope.update": {
        const envelope = yield* store.envelopeById(entry.entityId);
        if (envelope === undefined) return yield* gone("Koperta");
        const name = String(before.name);
        const taken = yield* store.envelopeNamed(h.id, name);
        if (taken !== undefined && taken.id !== envelope.id)
          return yield* new DuplicateEnvelopeName({ name });
        return yield* store.updateEnvelope(envelope.id, {
          name,
          color: String(before.color),
          icon: (before.icon as string | null) ?? null,
        });
      }
      case "envelope.archive":
      case "envelope.unarchive": {
        const envelope = yield* store.envelopeById(entry.entityId);
        if (envelope === undefined) return yield* gone("Koperta");
        return yield* store.setArchived(
          envelope.id,
          entry.action === "envelope.unarchive",
        );
      }
      case "envelope.delete": {
        const saved = before.envelope as store.EnvelopeRow;
        if ((yield* store.envelopeNamed(h.id, saved.name)) !== undefined)
          return yield* new DuplicateEnvelopeName({ name: saved.name });
        yield* store.insertEnvelope({
          id: saved.id,
          householdId: h.id,
          name: saved.name,
          color: saved.color,
          icon: saved.icon,
          position: saved.position,
          archivedAt:
            saved.archivedAt === null
              ? null
              : new Date(String(saved.archivedAt)),
        });
        for (const plan of (before.plans as Array<store.PlanRow>) ?? []) {
          const period = yield* store.periodById(plan.periodId);
          if (period !== undefined && period.closedAt === null)
            yield* store.upsertPlan(plan);
        }
        return;
      }
      case "period.end": {
        yield* setEnd(user.id as UserId, entry.entityId, String(before.endsOn));
        return;
      }
    }
    return yield* new CannotUndo({ reason: "Tej zmiany nie da się cofnąć" });
  });

/** F37: by somebody who may make that change; refused when it breaks a rule. */
export const undo = Effect.fn("log.undo")(function* (
  userId: UserId,
  id: string,
) {
  const entry = yield* store.logById(id);
  if (entry === undefined) return yield* new LogEntryNotFound({ id });
  const { household, member, user } = yield* householdFor(
    userId,
    entry.householdId,
  ).pipe(
    Effect.catchTag("HouseholdNotFound", () =>
      Effect.fail(new LogEntryNotFound({ id })),
    ),
  );
  if (entry.undoneAt !== null)
    return yield* new CannotUndo({ reason: "Już cofnięte" });
  if (!mayUndo(entry, member)) return yield* new Forbidden();
  yield* inTx(
    [householdKey(household.id), walletKey(userId)],
    Effect.gen(function* () {
      yield* undoEntry(household, user, entry).pipe(
        Effect.catchTags({
          PeriodNotFound: refuse,
          EnvelopeNotFound: refuse,
          MemberNotFound: refuse,
          DateOutsidePeriod: refuse,
          InvalidPeriodEnd: refuse,
          PeriodNotCurrent: refuse,
          PeriodClosed: refuse,
          MemberFrozen: refuse,
          WalletWouldGoNegative: refuse,
          WalletNegative: refuse,
          DuplicateEnvelopeName: refuse,
        }),
      );
      yield* store.markUndone(id, userId);
    }),
  );
});
