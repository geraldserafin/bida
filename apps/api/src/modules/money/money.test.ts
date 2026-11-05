import type { SaveExpense, SaveRule, UserId } from "@bida/api-contract";
import { assert, layer } from "@effect/vitest";
import { DateTime, Effect, Layer } from "effect";
import { SqlClient } from "effect/sql";
import { DbLive } from "../../platform/db.ts";
import { insertUser, resetDb, TestMailer } from "../../platform/testing.ts";
import { account } from "../account/account.module.ts";
import { envelopes } from "../envelopes/envelopes.module.ts";
import { expenses } from "../expenses/expenses.module.ts";
import { households, log, members } from "../households/households.module.ts";
import { addDays, localDay } from "../ledger/ledger.module.ts";
import { recurring } from "../recurring/recurring.module.ts";
import { sync } from "../sync/sync.module.ts";
import { wallet } from "../wallet/wallet.module.ts";

// Real services on the test database: the rules about money are the point.
const TestLayer = Layer.mergeAll(DbLive, TestMailer);

const today = () => localDay(new Date(), "Europe/Warsaw");
const now = () => DateTime.makeUnsafe(new Date());

const income = (userId: UserId, amountMinor: number, estimated = false) =>
  wallet.addIncome(userId, {
    amountMinor,
    onDate: today(),
    note: null,
    estimated,
  });

/** Ann with a household "Dom" (default envelopes) and 1000 zł in the wallet. */
const setup = Effect.gen(function* () {
  yield* resetDb;
  const ann = yield* insertUser("ann@example.com");
  const bob = yield* insertUser("bob@example.com");
  const home = yield* households.create(ann.id, { name: "Dom" });
  const list = yield* envelopes.list(ann.id, home.id);
  const food = list.find((e) => e.name === "Jedzenie");
  const fun = list.find((e) => e.name === "Rozrywka");
  if (food === undefined || fun === undefined)
    return yield* Effect.die("no envelopes");
  yield* income(ann.id, 100_000);
  return { ann, bob, home, food, fun, period: home.current };
});

const join = (
  owner: UserId,
  householdId: string,
  user: { id: UserId; email: string },
) =>
  Effect.gen(function* () {
    const invitation = yield* members.invite(
      owner,
      householdId,
      user.email,
      "member",
    );
    yield* members.accept(user.id, invitation.id);
  });

const spend = (
  userId: UserId,
  householdId: string,
  envelopeId: string,
  amountMinor: number,
  extra: Partial<SaveExpense> = {},
) =>
  expenses.create(userId, householdId, {
    envelopeId,
    amountMinor,
    spentAt: now(),
    title: null,
    forWhom: null,
    forWhomUserId: null,
    ...extra,
  });

/** Makes the current period of a household end yesterday, so the next sync closes it. */
const endYesterday = (householdId: string) =>
  Effect.gen(function* () {
    const sql = yield* SqlClient.SqlClient;
    yield* sql`UPDATE periods SET starts_on = ${addDays(today(), -30)}::date,
      ends_on = ${addDays(today(), -1)}::date
      WHERE household_id = ${householdId} AND closed_at IS NULL`;
  });

const rule = (input: Partial<SaveRule> & Pick<SaveRule, "kind">): SaveRule => ({
  householdId: null,
  envelopeId: null,
  name: "Reguła",
  amountMinor: 1_000,
  estimated: false,
  frequency: "monthly",
  dayOfMonth: Number(today().slice(8, 10)),
  everyWeeks: null,
  anchorOn: null,
  startsOn: today(),
  target: null,
  active: true,
  ...input,
});

layer(TestLayer)("households and periods (F05, F06, F24)", (it) => {
  it.effect(
    "a new household has an owner, the default envelopes and a current period",
    () =>
      Effect.gen(function* () {
        const { ann, home } = yield* setup;
        assert.strictEqual(home.role, "owner");
        assert.deepStrictEqual(home.cycle, {
          kind: "monthly",
          day: 1,
          weeks: null,
          anchorOn: null,
        });
        assert.strictEqual(home.timeZone, "Europe/Warsaw");
        assert.strictEqual(home.current.startsOn, `${today().slice(0, 8)}01`);
        assert.isTrue(home.current.endsOn >= today());
        assert.isNull(home.next);
        const names = (yield* envelopes.list(ann.id, home.id)).map(
          (e) => e.name,
        );
        assert.strictEqual(names.length, 7);
        assert.include(names, "Mieszkanie i rachunki");
      }),
  );

  it.effect("only two periods are open; the next one copies the plans", () =>
    Effect.gen(function* () {
      const { ann, home, food, period } = yield* setup;
      yield* envelopes.setPlan(ann.id, period.id, food.id, 40_000);
      const next = yield* households.openNextPeriod(ann.id, home.id);
      assert.strictEqual(next.startsOn, addDays(period.endsOn, 1));
      const again = yield* households
        .openNextPeriod(ann.id, home.id)
        .pipe(Effect.flip);
      assert.strictEqual(again._tag, "NextPeriodOpen");
      const summary = yield* households.summary(ann.id, next.id);
      assert.strictEqual(
        summary.envelopes.find((e) => e.envelopeId === food.id)?.planMinor,
        40_000,
      );
    }),
  );

  it.effect(
    "the end moves, not before today and not over the next period",
    () =>
      Effect.gen(function* () {
        const { ann, home, period } = yield* setup;
        const early = yield* households
          .setEnd(ann.id, period.id, addDays(today(), -1))
          .pipe(Effect.flip);
        assert.deepStrictEqual(early._tag, "InvalidPeriodEnd");
        const next = yield* households.openNextPeriod(ann.id, home.id);
        const over = yield* households
          .setEnd(ann.id, period.id, next.endsOn)
          .pipe(Effect.flip);
        assert.strictEqual(over._tag, "InvalidPeriodEnd");
        const newEnd = addDays(period.endsOn, 3);
        yield* households.setEnd(ann.id, period.id, newEnd);
        const moved = yield* households.get(ann.id, home.id);
        assert.strictEqual(moved.current.endsOn, newEnd);
        // no gap: the next one starts the day after, and counts from there
        assert.strictEqual(moved.next?.startsOn, addDays(newEnd, 1));
        assert.strictEqual(
          moved.cycle.day,
          Number(addDays(newEnd, 1).slice(8, 10)),
        );
      }),
  );

  it.effect("a member cannot rename, move the end or delete", () =>
    Effect.gen(function* () {
      const { ann, bob, home, period } = yield* setup;
      yield* join(ann.id, home.id, bob);
      assert.strictEqual(
        (yield* households.rename(bob.id, home.id, "X").pipe(Effect.flip))._tag,
        "Forbidden",
      );
      assert.strictEqual(
        (yield* households.setEnd(bob.id, period.id, today()).pipe(Effect.flip))
          ._tag,
        "Forbidden",
      );
      assert.strictEqual(
        (yield* households.remove(bob.id, home.id).pipe(Effect.flip))._tag,
        "Forbidden",
      );
    }),
  );
});

layer(TestLayer)("wallet, transfers and withdrawals (F31, F32)", (it) => {
  it.effect("wpływy − przelewy + wycofania, with the unconfirmed part", () =>
    Effect.gen(function* () {
      const { ann, period } = yield* setup;
      yield* income(ann.id, 20_000, true);
      assert.deepStrictEqual(yield* wallet.get(ann.id), {
        balanceMinor: 120_000,
        unconfirmedMinor: 20_000,
      });
      const moved = yield* households.transfer(ann.id, period.id, 110_000);
      // 10 000 of it came from the estimated income
      assert.isTrue(moved.usedUnconfirmed);
      assert.strictEqual(moved.walletMinor, 10_000);
      yield* households.withdraw(ann.id, period.id, 5_000);
      assert.strictEqual((yield* wallet.get(ann.id)).balanceMinor, 15_000);
    }),
  );

  it.effect("no transfer of more than the wallet holds", () =>
    Effect.gen(function* () {
      const { ann, period } = yield* setup;
      const error = yield* households
        .transfer(ann.id, period.id, 100_001)
        .pipe(Effect.flip);
      assert.strictEqual(error._tag, "NotEnoughMoney");
    }),
  );

  it.effect("a withdrawal is at most the share and at most what is there", () =>
    Effect.gen(function* () {
      const { ann, bob, home, food, period } = yield* setup;
      yield* join(ann.id, home.id, bob);
      yield* income(bob.id, 50_000);
      yield* households.transfer(ann.id, period.id, 50_000);
      yield* households.transfer(bob.id, period.id, 10_000);
      yield* envelopes.setPlan(ann.id, period.id, food.id, 60_000);
      yield* spend(bob.id, home.id, food.id, 50_000);
      // ann's share is 50 000, but only 10 000 is left
      const error = yield* households
        .withdraw(ann.id, period.id, 10_001)
        .pipe(Effect.flip);
      assert.strictEqual(error._tag, "NotEnoughMoney");
      if (error._tag === "NotEnoughMoney")
        assert.strictEqual(error.availableMinor, 10_000);
      const bobs = yield* households
        .withdraw(bob.id, period.id, 1)
        .pipe(Effect.flip);
      assert.strictEqual(bobs._tag, "NotEnoughMoney");
    }),
  );
});

layer(TestLayer)("an expense has to fit (F08, F19)", (it) => {
  it.effect("step 1: the plan grows by itself out of free money", () =>
    Effect.gen(function* () {
      const { ann, home, food, period } = yield* setup;
      yield* households.transfer(ann.id, period.id, 50_000);
      yield* envelopes.setPlan(ann.id, period.id, food.id, 10_000);
      const result = yield* spend(ann.id, home.id, food.id, 15_000);
      assert.strictEqual(result.raisedPlanMinor, 5_000);
      assert.strictEqual(result.transferredMinor, 0);
      const summary = yield* households.summary(ann.id, period.id);
      assert.strictEqual(summary.balanceMinor, 35_000);
      assert.strictEqual(
        summary.envelopes.find((e) => e.envelopeId === food.id)?.planMinor,
        15_000,
      );
    }),
  );

  it.effect("step 2: no free money, the user brings it from the wallet", () =>
    Effect.gen(function* () {
      const { ann, home, food, fun, period } = yield* setup;
      yield* households.transfer(ann.id, period.id, 20_000);
      yield* envelopes.setPlan(ann.id, period.id, fun.id, 20_000);
      const error = yield* spend(ann.id, home.id, food.id, 5_000).pipe(
        Effect.flip,
      );
      assert.strictEqual(error._tag, "PlanTooSmall");
      if (error._tag !== "PlanTooSmall") return;
      assert.strictEqual(error.planShortMinor, 5_000);
      assert.strictEqual(error.freeMinor, 0);
      assert.strictEqual(error.transferMinor, 5_000);
      const result = yield* spend(ann.id, home.id, food.id, 5_000, {
        decision: {
          raisePlan: true,
          transferMinor: 5_000,
          allowNegativeWallet: false,
        },
      });
      assert.strictEqual(result.transferredMinor, 5_000);
      assert.strictEqual(result.raisedPlanMinor, 5_000);
      assert.strictEqual((yield* wallet.get(ann.id)).balanceMinor, 75_000);
    }),
  );

  it.effect("step 3: an empty wallet goes below zero only when confirmed", () =>
    Effect.gen(function* () {
      const { ann, home, food, period } = yield* setup;
      yield* households.transfer(ann.id, period.id, 100_000);
      yield* envelopes.setPlan(ann.id, period.id, food.id, 100_000);
      const decision = {
        raisePlan: true,
        transferMinor: 20_000,
        allowNegativeWallet: false,
      };
      const error = yield* spend(ann.id, home.id, food.id, 120_000, {
        decision,
      }).pipe(Effect.flip);
      assert.strictEqual(error._tag, "WalletWouldGoNegative");
      yield* spend(ann.id, home.id, food.id, 120_000, {
        decision: { ...decision, allowNegativeWallet: true },
      });
      assert.strictEqual((yield* wallet.get(ann.id)).balanceMinor, -20_000);
      // while the wallet is below zero no transfer goes out of it
      yield* income(ann.id, 1_000);
      const blocked = yield* households
        .transfer(ann.id, period.id, 500)
        .pipe(Effect.flip);
      assert.strictEqual(blocked._tag, "WalletNegative");
    }),
  );

  it.effect("the plan is fine but the balance is not: bring money", () =>
    Effect.gen(function* () {
      const { ann, home, food, period } = yield* setup;
      yield* households.transfer(ann.id, period.id, 1_000);
      yield* envelopes.setPlan(ann.id, period.id, food.id, 5_000);
      const error = yield* spend(ann.id, home.id, food.id, 3_000).pipe(
        Effect.flip,
      );
      assert.strictEqual(error._tag, "NotEnoughInPeriod");
      if (error._tag === "NotEnoughInPeriod")
        assert.strictEqual(error.transferMinor, 2_000);
    }),
  );

  it.effect(
    "a plan cannot go below what was spent; plans may exceed the balance",
    () =>
      Effect.gen(function* () {
        const { ann, home, food, fun, period } = yield* setup;
        yield* households.transfer(ann.id, period.id, 10_000);
        yield* envelopes.setPlan(ann.id, period.id, food.id, 10_000);
        yield* spend(ann.id, home.id, food.id, 4_000);
        const low = yield* envelopes
          .setPlan(ann.id, period.id, food.id, 3_999)
          .pipe(Effect.flip);
        assert.strictEqual(low._tag, "PlanBelowSpent");
        const summary = yield* envelopes.setPlan(
          ann.id,
          period.id,
          fun.id,
          50_000,
        );
        assert.isTrue(summary.plansExceedBalance);
        // balance 6 000; the plans still hold 6 000 (food) + 50 000 (fun)
        assert.strictEqual(summary.freeMinor, 6_000 - 56_000);
      }),
  );

  it.effect(
    "the date is in the current period; the next one is only for planning",
    () =>
      Effect.gen(function* () {
        const { ann, home, food, period } = yield* setup;
        yield* households.transfer(ann.id, period.id, 10_000);
        const before = DateTime.makeUnsafe(
          new Date(`${addDays(period.startsOn, -1)}T12:00:00Z`),
        );
        const error = yield* spend(ann.id, home.id, food.id, 100, {
          spentAt: before,
        }).pipe(Effect.flip);
        assert.strictEqual(error._tag, "DateOutsidePeriod");
        const next = yield* households.openNextPeriod(ann.id, home.id);
        yield* households.transfer(ann.id, next.id, 1_000);
        const summary = yield* households.summary(ann.id, next.id);
        assert.strictEqual(summary.balanceMinor, 1_000);
      }),
  );

  it.effect("the author changes their expense, an owner anybody's", () =>
    Effect.gen(function* () {
      const { ann, bob, home, food, period } = yield* setup;
      yield* join(ann.id, home.id, bob);
      yield* households.transfer(ann.id, period.id, 10_000);
      const { expense } = yield* spend(ann.id, home.id, food.id, 1_000);
      const error = yield* expenses
        .remove(bob.id, expense.id)
        .pipe(Effect.flip);
      assert.strictEqual(error._tag, "Forbidden");
      const { expense: bobs } = yield* spend(bob.id, home.id, food.id, 500);
      yield* expenses.remove(ann.id, bobs.id);
      const summary = yield* households.summary(ann.id, period.id);
      assert.strictEqual(summary.balanceMinor, 9_000);
    }),
  );

  it.effect("for whom only filters and does not change shares (F28)", () =>
    Effect.gen(function* () {
      const { ann, bob, home, food, period } = yield* setup;
      yield* join(ann.id, home.id, bob);
      yield* households.transfer(ann.id, period.id, 10_000);
      yield* spend(ann.id, home.id, food.id, 1_000, {
        forWhom: "member",
        forWhomUserId: bob.id,
      });
      yield* spend(ann.id, home.id, food.id, 2_000, { forWhom: "shared" });
      const forBob = yield* expenses.list(ann.id, { forWhom: bob.id });
      assert.deepStrictEqual(
        forBob.map((x) => x.forWhomName),
        ["bob@example.com"],
      );
      const summary = yield* households.summary(ann.id, period.id);
      assert.strictEqual(
        summary.shares.find((s) => s.userId === bob.id)?.shareMinor,
        0,
      );
      assert.strictEqual(
        summary.shares.find((s) => s.userId === ann.id)?.shareMinor,
        7_000,
      );
    }),
  );
});

layer(TestLayer)("closing a period (F24, F35) and shares (F33)", (it) => {
  it.effect("what is left goes on as nobody's money and is spent first", () =>
    Effect.gen(function* () {
      const { ann, bob, home, food, period } = yield* setup;
      yield* join(ann.id, home.id, bob);
      yield* households.transfer(ann.id, period.id, 30_000);
      yield* envelopes.setPlan(ann.id, period.id, food.id, 30_000);
      yield* spend(ann.id, home.id, food.id, 10_000);
      yield* endYesterday(home.id);

      const result = yield* sync.run(bob.id);
      assert.strictEqual(result.closedPeriods, 1);
      assert.strictEqual(result.openedPeriods, 1);
      assert.deepStrictEqual(
        result.summaries.map((s) => [s.spentMinor, s.carryOutMinor]),
        [[10_000, 20_000]],
      );
      // the summary shows once per member
      yield* sync.seen(bob.id, period.id);
      assert.strictEqual((yield* sync.summaries(bob.id)).length, 0);
      assert.strictEqual((yield* sync.summaries(ann.id)).length, 1);

      const current = (yield* households.get(ann.id, home.id)).current;
      assert.notStrictEqual(current.id, period.id);
      // plans were copied
      yield* income(bob.id, 5_000);
      yield* households.transfer(bob.id, current.id, 5_000);
      yield* spend(bob.id, home.id, food.id, 22_000);
      const summary = yield* households.summary(ann.id, current.id);
      assert.strictEqual(summary.carryInMinor, 20_000);
      assert.strictEqual(summary.nobodyLeftMinor, 0);
      // 20 000 of nobody's money, then 2 000 of bob's 5 000
      assert.strictEqual(
        summary.shares.find((s) => s.userId === bob.id)?.shareMinor,
        3_000,
      );
      assert.strictEqual(
        summary.shares.find((s) => s.userId === ann.id)?.shareMinor,
        0,
      );
      assert.strictEqual(summary.balanceMinor, 3_000);
    }),
  );

  it.effect("a closed period is frozen; only the title changes", () =>
    Effect.gen(function* () {
      const { ann, home, food, period } = yield* setup;
      yield* households.transfer(ann.id, period.id, 10_000);
      const { expense } = yield* spend(ann.id, home.id, food.id, 1_000);
      yield* endYesterday(home.id);
      yield* sync.run(ann.id);
      const payload = {
        envelopeId: food.id,
        amountMinor: 2_000,
        spentAt: expense.spentAt,
        title: null,
        forWhom: null,
        forWhomUserId: null,
      };
      const error = yield* expenses
        .update(ann.id, expense.id, payload)
        .pipe(Effect.flip);
      assert.strictEqual(error._tag, "PeriodClosed");
      const renamed = yield* expenses.update(ann.id, expense.id, {
        ...payload,
        amountMinor: 1_000,
        title: "Biedronka",
      });
      assert.strictEqual(renamed.expense.title, "Biedronka");
      const plan = yield* envelopes
        .setPlan(ann.id, period.id, food.id, 5_000)
        .pipe(Effect.flip);
      assert.strictEqual(plan._tag, "PeriodClosed");
    }),
  );

  it.effect("the log of a closed period goes", () =>
    Effect.gen(function* () {
      const { ann, home, period } = yield* setup;
      yield* households.transfer(ann.id, period.id, 1_000);
      assert.strictEqual((yield* log.list(ann.id, home.id)).length, 1);
      yield* endYesterday(home.id);
      yield* sync.run(ann.id);
      assert.strictEqual((yield* log.list(ann.id, home.id)).length, 0);
    }),
  );
});

layer(TestLayer)("the app start (F25, F26, F34)", (it) => {
  it.effect(
    "incomes, then transfers, then expenses; again it does nothing",
    () =>
      Effect.gen(function* () {
        yield* resetDb;
        const ann = yield* insertUser("ann@example.com");
        const home = yield* households.create(ann.id, { name: "Dom" });
        const food = (yield* envelopes.list(ann.id, home.id))[0];
        if (food === undefined) return yield* Effect.die("no envelope");
        // the wallet is empty: the transfer needs the income first, the expense the transfer
        yield* recurring.create(
          ann.id,
          rule({ kind: "income", amountMinor: 100_000 }),
        );
        yield* recurring.create(
          ann.id,
          rule({
            kind: "transfer",
            householdId: home.id,
            target: "current",
            amountMinor: 60_000,
          }),
        );
        yield* recurring.create(
          ann.id,
          rule({
            kind: "expense",
            householdId: home.id,
            envelopeId: food.id,
            amountMinor: 20_000,
          }),
        );
        const first = yield* sync.run(ann.id);
        assert.deepStrictEqual(
          [first.incomes, first.transfers, first.expenses, first.todo],
          [1, 1, 1, 0],
        );
        const second = yield* sync.run(ann.id);
        assert.deepStrictEqual(
          [second.incomes, second.transfers, second.expenses],
          [0, 0, 0],
        );
        assert.strictEqual((yield* wallet.get(ann.id)).balanceMinor, 40_000);
        const summary = yield* households.summary(ann.id, home.current.id);
        assert.strictEqual(summary.balanceMinor, 40_000);
        // the rule is part of the plan, so the expense fit
        const plan = summary.envelopes.find((e) => e.envelopeId === food.id);
        assert.strictEqual(plan?.recurringMinor, 20_000);
        assert.strictEqual(plan?.spentMinor, 20_000);
      }),
  );

  it.effect("the plan holds amount × occurrences of a rule in the period", () =>
    Effect.gen(function* () {
      const { ann, home, fun, period } = yield* setup;
      yield* recurring.create(
        ann.id,
        rule({
          kind: "expense",
          householdId: home.id,
          envelopeId: fun.id,
          amountMinor: 2_000,
          frequency: "weeks",
          dayOfMonth: null,
          everyWeeks: 1,
          anchorOn: period.startsOn,
          startsOn: period.startsOn,
        }),
      );
      const weeks =
        Math.floor(
          (Date.parse(period.endsOn) - Date.parse(period.startsOn)) /
            (7 * 86_400_000),
        ) + 1;
      const summary = yield* households.summary(ann.id, period.id);
      const figures = summary.envelopes.find((e) => e.envelopeId === fun.id);
      assert.strictEqual(figures?.recurringMinor, weeks * 2_000);
      // setting the plan keeps the recurring part apart
      yield* envelopes.setPlan(ann.id, period.id, fun.id, weeks * 2_000 + 500);
      const after = yield* households.summary(ann.id, period.id);
      const set = after.envelopes.find((e) => e.envelopeId === fun.id);
      assert.strictEqual(set?.manualMinor, 500);
    }),
  );

  it.effect(
    "a transfer the wallet cannot pay waits in the owner's to-do list",
    () =>
      Effect.gen(function* () {
        const { ann, bob, home } = yield* setup;
        yield* join(ann.id, home.id, bob);
        yield* recurring.create(
          bob.id,
          rule({
            kind: "transfer",
            householdId: home.id,
            target: "current",
            amountMinor: 5_000,
          }),
        );
        const result = yield* sync.run(bob.id);
        assert.strictEqual(result.transfers, 0);
        const items = yield* sync.todo(bob.id);
        assert.deepStrictEqual(
          items.map((t) => t.kind),
          ["transfer_no_money"],
        );
        // a wallet's matters are its owner's only
        assert.strictEqual((yield* sync.todo(ann.id)).length, 0);
        yield* income(bob.id, 5_000);
        const item = items[0];
        if (item === undefined) return;
        yield* sync.resolve(bob.id, item.id, { amountMinor: 5_000 });
        assert.strictEqual((yield* sync.todo(bob.id)).length, 0);
        assert.strictEqual((yield* wallet.get(bob.id)).balanceMinor, 0);
      }),
  );

  it.effect("an estimated income goes in and waits for its amount", () =>
    Effect.gen(function* () {
      const { ann, home, period } = yield* setup;
      yield* recurring.create(
        ann.id,
        rule({ kind: "income", amountMinor: 30_000, estimated: true }),
      );
      yield* sync.run(ann.id);
      assert.deepStrictEqual(yield* wallet.get(ann.id), {
        balanceMinor: 130_000,
        unconfirmedMinor: 30_000,
      });
      yield* households.transfer(ann.id, period.id, 120_000);
      const [item] = yield* sync.todo(ann.id);
      if (item === undefined) return yield* Effect.die("no item");
      assert.strictEqual(item.kind, "income_estimate");
      // 25 000 less would put the wallet at −15 000
      const error = yield* sync
        .resolve(ann.id, item.id, { amountMinor: 5_000 })
        .pipe(Effect.flip);
      assert.strictEqual(error._tag, "WalletWouldGoNegative");
      // take the missing amount back from the household
      yield* sync.resolve(ann.id, item.id, {
        amountMinor: 5_000,
        correction: { allowNegative: false, withdrawFromPeriodId: period.id },
      });
      assert.deepStrictEqual(yield* wallet.get(ann.id), {
        balanceMinor: 0,
        unconfirmedMinor: 0,
      });
      void home;
    }),
  );

  it.effect(
    "a recurring expense that does not fit waits for the household",
    () =>
      Effect.gen(function* () {
        const { ann, bob, home, food } = yield* setup;
        yield* join(ann.id, home.id, bob);
        yield* recurring.create(
          ann.id,
          rule({
            kind: "expense",
            householdId: home.id,
            envelopeId: food.id,
            amountMinor: 9_000,
          }),
        );
        const result = yield* sync.run(ann.id);
        assert.strictEqual(result.expenses, 0);
        const forBob = yield* sync.todo(bob.id);
        assert.deepStrictEqual(
          forBob.map((t) => t.kind),
          ["expense_not_fit"],
        );
        const item = forBob[0];
        if (item === undefined) return;
        // bob brings the money; the expense is ann's (she made the rule)
        yield* income(bob.id, 9_000);
        yield* sync.resolve(bob.id, item.id, {
          amountMinor: 9_000,
          decision: {
            raisePlan: true,
            transferMinor: 9_000,
            allowNegativeWallet: false,
          },
        });
        assert.strictEqual((yield* sync.todo(ann.id)).length, 0);
        const [expense] = yield* expenses.list(ann.id, {
          householdId: home.id,
        });
        assert.strictEqual(expense?.createdBy, ann.id);
      }),
  );
});

layer(TestLayer)(
  "members, leaving and negative shares (F14, F22, F36, F04)",
  (it) => {
    /** Bob spent 3 000 of ann's money: his share is −3 000. */
    const inDebt = Effect.gen(function* () {
      const s = yield* setup;
      yield* join(s.ann.id, s.home.id, s.bob);
      yield* households.transfer(s.ann.id, s.period.id, 10_000);
      yield* spend(s.bob.id, s.home.id, s.food.id, 3_000);
      return s;
    });

    it.effect(
      "with a negative share nobody leaves, and nothing is deleted",
      () =>
        Effect.gen(function* () {
          const { ann, bob, home } = yield* inDebt;
          const leaving = yield* members
            .leave(bob.id, home.id, true)
            .pipe(Effect.flip);
          assert.strictEqual(leaving._tag, "NegativeShare");
          if (leaving._tag === "NegativeShare")
            assert.deepStrictEqual(
              leaving.entries.map((e) => [e.name, e.shareMinor]),
              [["bob@example.com", -3_000]],
            );
          const deleting = yield* households
            .remove(ann.id, home.id)
            .pipe(Effect.flip);
          assert.strictEqual(deleting._tag, "NegativeShare");
          const account_ = yield* account
            .remove(bob.id, "bob@example.com")
            .pipe(Effect.flip);
          assert.strictEqual(account_._tag, "NegativeShare");
          const removing = yield* members
            .remove(ann.id, home.id, bob.id)
            .pipe(Effect.flip);
          assert.strictEqual(removing._tag, "NegativeShare");
        }),
    );

    it.effect("a frozen member cannot spend and goes once even", () =>
      Effect.gen(function* () {
        const { ann, bob, home, food, period } = yield* inDebt;
        yield* members.freeze(ann.id, home.id, bob.id, true);
        const error = yield* spend(bob.id, home.id, food.id, 100).pipe(
          Effect.flip,
        );
        assert.strictEqual(error._tag, "MemberFrozen");
        yield* income(bob.id, 3_000);
        yield* households.transfer(bob.id, period.id, 3_000);
        const list = yield* members.list(ann.id, home.id);
        assert.deepStrictEqual(
          list.map((m) => m.email),
          ["ann@example.com"],
        );
      }),
    );

    it.effect("leaving takes the share back to the wallet", () =>
      Effect.gen(function* () {
        const { ann, bob, home, period } = yield* setup;
        yield* join(ann.id, home.id, bob);
        yield* income(bob.id, 4_000);
        yield* households.transfer(bob.id, period.id, 4_000);
        yield* members.leave(bob.id, home.id, true);
        assert.strictEqual((yield* wallet.get(bob.id)).balanceMinor, 4_000);
        const gone = yield* households.get(bob.id, home.id).pipe(Effect.flip);
        assert.strictEqual(gone._tag, "HouseholdNotFound");
        void ann;
      }),
    );

    it.effect("there is always an owner; owners can be several", () =>
      Effect.gen(function* () {
        const { ann, bob, home } = yield* setup;
        yield* join(ann.id, home.id, bob);
        const last = yield* members
          .leave(ann.id, home.id, true)
          .pipe(Effect.flip);
        assert.strictEqual(last._tag, "LastOwner");
        const demote = yield* members
          .setRole(ann.id, home.id, ann.id, "member")
          .pipe(Effect.flip);
        assert.strictEqual(demote._tag, "LastOwner");
        yield* members.setRole(ann.id, home.id, bob.id, "owner");
        yield* members.setRole(bob.id, home.id, ann.id, "member");
        yield* members.leave(ann.id, home.id, true);
        assert.strictEqual(
          (yield* households.get(bob.id, home.id)).role,
          "owner",
        );
      }),
    );

    it.effect("deleting a household gives positive shares back", () =>
      Effect.gen(function* () {
        const { ann, home, period } = yield* setup;
        yield* households.transfer(ann.id, period.id, 25_000);
        yield* households.remove(ann.id, home.id);
        assert.strictEqual((yield* wallet.get(ann.id)).balanceMinor, 100_000);
      }),
    );

    it.effect(
      "deleting the account: typed address; shares stay as nobody's",
      () =>
        Effect.gen(function* () {
          const { ann, bob, home, period } = yield* setup;
          yield* join(ann.id, home.id, bob);
          yield* households.transfer(ann.id, period.id, 10_000);
          const wrong = yield* account
            .remove(ann.id, "bob@example.com")
            .pipe(Effect.flip);
          assert.strictEqual(wrong._tag, "ConfirmationMismatch");
          yield* account.remove(ann.id, "ann@example.com");
          const summary = yield* households.summary(bob.id, period.id);
          assert.strictEqual(summary.balanceMinor, 10_000);
          assert.strictEqual(summary.nobodyLeftMinor, 10_000);
          // the longest member became the owner
          assert.strictEqual(
            (yield* households.get(bob.id, home.id)).role,
            "owner",
          );
        }),
    );
  },
);

layer(TestLayer)("the change log (F37)", (it) => {
  it.effect("a change is undone by somebody who may make it", () =>
    Effect.gen(function* () {
      const { ann, bob, home, food, period } = yield* setup;
      yield* join(ann.id, home.id, bob);
      yield* households.transfer(ann.id, period.id, 10_000);
      yield* envelopes.setPlan(ann.id, period.id, food.id, 4_000);
      const { expense } = yield* spend(ann.id, home.id, food.id, 1_000);
      const entries = yield* log.list(bob.id, home.id);
      assert.deepStrictEqual(
        entries.map((e) => [e.action, e.canUndo]),
        [
          ["expense.create", false],
          ["plan.set", true],
          ["transfer", false],
        ],
      );
      const forbidden = yield* log
        .undo(bob.id, entries[0]?.id ?? "")
        .pipe(Effect.flip);
      assert.strictEqual(forbidden._tag, "Forbidden");
      yield* log.undo(ann.id, entries[0]?.id ?? "");
      assert.strictEqual(
        (yield* expenses.get(ann.id, expense.id).pipe(Effect.flip))._tag,
        "ExpenseNotFound",
      );
      yield* log.undo(bob.id, entries[1]?.id ?? "");
      const summary = yield* households.summary(ann.id, period.id);
      assert.strictEqual(
        summary.envelopes.find((e) => e.envelopeId === food.id)?.planMinor,
        0,
      );
    }),
  );

  it.effect("an undo that breaks a rule is refused", () =>
    Effect.gen(function* () {
      const { ann, home, food, period } = yield* setup;
      yield* households.transfer(ann.id, period.id, 10_000);
      yield* envelopes.setPlan(ann.id, period.id, food.id, 10_000);
      yield* spend(ann.id, home.id, food.id, 8_000);
      const transfer = (yield* log.list(ann.id, home.id)).find(
        (e) => e.action === "transfer",
      );
      // only 2 000 is left, the transfer cannot come back out
      const error = yield* log
        .undo(ann.id, transfer?.id ?? "")
        .pipe(Effect.flip);
      assert.strictEqual(error._tag, "NotEnoughMoney");
    }),
  );
});

layer(TestLayer)("envelopes (F12) and invitations (F13)", (it) => {
  it.effect(
    "names are unique; one with expenses is archived, not deleted",
    () =>
      Effect.gen(function* () {
        const { ann, home, food, period } = yield* setup;
        const dup = yield* envelopes
          .create(ann.id, home.id, {
            name: "jedzenie",
            color: "#112233",
            icon: null,
          })
          .pipe(Effect.flip);
        assert.strictEqual(dup._tag, "DuplicateEnvelopeName");
        yield* households.transfer(ann.id, period.id, 1_000);
        yield* spend(ann.id, home.id, food.id, 500);
        const used = yield* envelopes.remove(ann.id, food.id).pipe(Effect.flip);
        assert.strictEqual(used._tag, "EnvelopeHasExpenses");
        const archived = yield* envelopes.archive(ann.id, food.id, true);
        assert.isTrue(archived.archived);
        const summary = yield* households.summary(ann.id, period.id);
        assert.strictEqual(
          summary.envelopes.find((e) => e.envelopeId === food.id)?.planMinor,
          500,
        );
      }),
  );

  it.effect("an accepted invitation makes a member at once", () =>
    Effect.gen(function* () {
      const { ann, bob, home } = yield* setup;
      const invitation = yield* members.invite(
        ann.id,
        home.id,
        "BOB@example.com",
        "member",
      );
      assert.strictEqual((yield* members.mine(bob.id)).length, 1);
      const joined = yield* members.accept(bob.id, invitation.id);
      assert.strictEqual(joined.role, "member");
      assert.strictEqual(joined.memberCount, 2);
      const again = yield* members
        .invite(ann.id, home.id, "bob@example.com", "member")
        .pipe(Effect.flip);
      assert.strictEqual(again._tag, "AlreadyMember");
    }),
  );
});
