import {
  AllocationRuleNotFound,
  EnvelopeNotFound,
  RecurringIncomeNotFound,
  type UserId,
} from "@bida/api-contract";
import { assert, layer } from "@effect/vitest";
import { Effect, Layer } from "effect";
import { DbLive } from "../../platform/db.ts";
import { insertUser, resetDb } from "../../platform/testing.ts";
import {
  EnvelopesModule,
  EnvelopesService,
} from "../envelopes/envelopes.module.ts";
import { ExpensesModule } from "../expenses/expenses.module.ts";
import { IncomesModule, IncomesService } from "../incomes/incomes.module.ts";
import { MembersModule, MembersService } from "../members/members.module.ts";
import {
  OverviewModule,
  OverviewService,
} from "../overview/overview.module.ts";
import { RecurringModule, RecurringService } from "./recurring.module.ts";

const TestLayer = Layer.mergeAll(
  RecurringModule,
  EnvelopesModule,
  ExpensesModule,
  IncomesModule,
  MembersModule,
  OverviewModule,
).pipe(Layer.provideMerge(DbLive));

const look = { color: "#112233", icon: null } as const;
const July = { from: "2026-07-01", to: "2026-07-31" };
const August = { from: "2026-08-01", to: "2026-08-31" };

/** Ann earns a salary on the 10th and puts money into Home and its sub-envelope Rent. */
const setup = Effect.gen(function* () {
  yield* resetDb;
  const envelopes = yield* EnvelopesService;
  const recurring = yield* RecurringService;
  const ann = yield* insertUser();
  const bob = yield* insertUser();
  const home = yield* envelopes.create(ann.id, {
    parentId: null,
    name: "Home",
    ...look,
  });
  const rent = yield* envelopes.create(ann.id, {
    parentId: home.id,
    name: "Rent",
    ...look,
  });
  const salary = yield* recurring.createIncome(ann.id, {
    amountMinor: 500_000,
    dayOfMonth: 10,
    note: "salary",
    active: true,
  });
  const toHome = yield* recurring.createAllocationRule(ann.id, {
    envelopeId: home.id,
    amountMinor: 200_000,
    dayOfMonth: 11,
    note: null,
    active: true,
  });
  return { recurring, envelopes, ann, bob, home, rent, salary, toHome };
});

const rule = (envelopeId: string, amountMinor: number, day = 12) => ({
  envelopeId: envelopeId as never,
  amountMinor,
  dayOfMonth: day,
  note: null,
  active: true,
});

layer(TestLayer)("recurring incomes and allocation rules", (it) => {
  it.effect("rules belong to their user", () =>
    Effect.gen(function* () {
      const { recurring, ann, bob, home, salary, toHome } = yield* setup;

      assert.strictEqual((yield* recurring.listIncomes(ann.id)).length, 1);
      assert.deepStrictEqual(yield* recurring.listIncomes(bob.id), []);
      assert.deepStrictEqual(yield* recurring.listAllocationRules(bob.id), []);

      assert.instanceOf(
        yield* recurring
          .updateIncome(bob.id, salary.id, {
            amountMinor: 1,
            dayOfMonth: 1,
            note: null,
            active: true,
          })
          .pipe(Effect.flip),
        RecurringIncomeNotFound,
      );
      assert.instanceOf(
        yield* recurring
          .removeAllocationRule(bob.id, toHome.id)
          .pipe(Effect.flip),
        AllocationRuleNotFound,
      );
      // and an allocation rule needs an envelope the user can see
      assert.instanceOf(
        yield* recurring
          .createAllocationRule(bob.id, rule(home.id, 100))
          .pipe(Effect.flip),
        EnvelopeNotFound,
      );

      const edited = yield* recurring.updateIncome(ann.id, salary.id, {
        amountMinor: 600_000,
        dayOfMonth: 5,
        note: "raise",
        active: true,
      });
      assert.deepStrictEqual(
        [edited.amountMinor, edited.dayOfMonth],
        [600_000, 5],
      );
      yield* recurring.removeIncome(ann.id, salary.id);
      assert.deepStrictEqual(yield* recurring.listIncomes(ann.id), []);
    }),
  );

  it.effect("applying adds the income and the allocation on their days", () =>
    Effect.gen(function* () {
      const { recurring, envelopes, ann, home } = yield* setup;
      const incomes = yield* IncomesService;
      const overview = yield* OverviewService;

      assert.deepStrictEqual(yield* recurring.pending(ann.id, July), {
        incomes: 1,
        allocations: 1,
        expenses: 0,
        skipped: 0,
      });

      assert.deepStrictEqual(yield* recurring.apply(ann.id, July), {
        incomes: 1,
        allocations: 1,
        expenses: 0,
        skipped: 0,
      });

      const [income] = yield* incomes.list(ann.id, {});
      assert.deepStrictEqual(
        [income?.amountMinor, income?.receivedOn, income?.note],
        [500_000, "2026-07-10", "salary"],
      );
      const [allocation] = yield* envelopes.listAllocations(ann.id, {
        envelopeId: home.id,
      });
      assert.deepStrictEqual(
        [allocation?.amountMinor, allocation?.madeOn],
        [200_000, "2026-07-11"],
      );
      // the pool is what is left of the salary
      assert.strictEqual(
        (yield* overview.get(ann.id, July)).poolMinor,
        300_000,
      );

      // nothing is left to do, and applying again adds nothing
      assert.deepStrictEqual(yield* recurring.pending(ann.id, July), {
        incomes: 0,
        allocations: 0,
        expenses: 0,
        skipped: 0,
      });
      assert.deepStrictEqual(yield* recurring.apply(ann.id, July), {
        incomes: 0,
        allocations: 0,
        expenses: 0,
        skipped: 0,
      });
      assert.strictEqual((yield* incomes.list(ann.id, {})).length, 1);
    }),
  );

  it.effect("every month gets its own, on the day inside that month", () =>
    Effect.gen(function* () {
      const { recurring, ann } = yield* setup;
      const incomes = yield* IncomesService;
      yield* recurring.apply(ann.id, July);
      yield* recurring.apply(ann.id, August);
      // a month that starts on the 20th has the 10th at its end
      yield* recurring.apply(ann.id, { from: "2026-09-20", to: "2026-10-19" });

      assert.deepStrictEqual(
        (yield* incomes.list(ann.id, {})).map((i) => i.receivedOn),
        ["2026-10-10", "2026-08-10", "2026-07-10"],
      );
    }),
  );

  it.effect("paused and deleted rules do nothing", () =>
    Effect.gen(function* () {
      const { recurring, ann, salary, toHome } = yield* setup;
      yield* recurring.updateIncome(ann.id, salary.id, {
        amountMinor: salary.amountMinor,
        dayOfMonth: salary.dayOfMonth,
        note: null,
        active: false,
      });
      yield* recurring.removeAllocationRule(ann.id, toHome.id);

      assert.deepStrictEqual(yield* recurring.apply(ann.id, July), {
        incomes: 0,
        allocations: 0,
        expenses: 0,
        skipped: 0,
      });
    }),
  );

  it.effect("deleting a rule keeps what it made", () =>
    Effect.gen(function* () {
      const { recurring, envelopes, ann, home, salary, toHome } = yield* setup;
      const incomes = yield* IncomesService;
      yield* recurring.apply(ann.id, July);
      yield* recurring.removeIncome(ann.id, salary.id);
      yield* recurring.removeAllocationRule(ann.id, toHome.id);

      assert.strictEqual((yield* incomes.list(ann.id, {})).length, 1);
      assert.strictEqual(
        (yield* envelopes.listAllocations(ann.id, { envelopeId: home.id }))
          .length,
        1,
      );
    }),
  );

  it.effect("a sub-envelope is funded from what was put into its parent", () =>
    Effect.gen(function* () {
      const { recurring, envelopes, ann, home, rent } = yield* setup;
      yield* recurring.createAllocationRule(ann.id, rule(rent.id, 80_000, 12));

      // the rule for Home comes first, so Rent has the money to be given
      const result = yield* recurring.apply(ann.id, July);
      assert.deepStrictEqual([result.allocations, result.skipped], [2, 0]);
      const rentAllocations = yield* envelopes.listAllocations(ann.id, {
        envelopeId: rent.id,
      });
      assert.strictEqual(rentAllocations[0]?.amountMinor, 80_000);
      assert.strictEqual(home.id !== rent.id, true);
    }),
  );

  it.effect(
    "an allocation the envelope cannot take is skipped, not failed",
    () =>
      Effect.gen(function* () {
        const { recurring, ann, rent } = yield* setup;
        // only 200 000 go into Home, but Rent is to get 250 000 of it
        yield* recurring.createAllocationRule(ann.id, rule(rent.id, 250_000));

        assert.deepStrictEqual(yield* recurring.apply(ann.id, July), {
          incomes: 1,
          allocations: 1,
          expenses: 0,
          skipped: 1,
        });
      }),
  );

  it.effect("leaving an envelope takes the rules for it along", () =>
    Effect.gen(function* () {
      const { recurring, bob, home } = yield* setup;
      const members = yield* MembersService;
      yield* members.add(home.id, bob.id, "member");
      yield* recurring.createAllocationRule(bob.id, rule(home.id, 1_000));
      yield* members.remove(bob.id, home.id, bob.id as UserId);

      // leaving removes the rule, so nothing is left to apply for Bob
      assert.deepStrictEqual(
        (yield* recurring.listAllocationRules(bob.id)).length,
        0,
      );
    }),
  );
});
