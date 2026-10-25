import {
  ContributionId,
  ContributionNotFound,
  Forbidden,
  PeriodId,
  PeriodNotFound,
  type UserId,
} from "@bida/api-contract";
import { assert, layer } from "@effect/vitest";
import { DateTime, Effect, Layer } from "effect";
import { DbLive } from "../../platform/db.ts";
import { insertUser, resetDb, TestSpace } from "../../platform/testing.ts";
import { BudgetsModule, BudgetsService } from "../budgets/budgets.module.ts";
import {
  CategoriesModule,
  CategoriesService,
} from "../categories/categories.module.ts";
import {
  ExpensesModule,
  ExpensesService,
} from "../expenses/expenses.module.ts";
import {
  ContributionsModule,
  ContributionsService,
} from "./contributions.module.ts";

const TestLayer = Layer.mergeAll(
  ContributionsModule,
  ExpensesModule,
  BudgetsModule,
  CategoriesModule,
).pipe(Layer.provideMerge(DbLive), Layer.provideMerge(TestSpace()));

const at = (iso: string) => DateTime.makeUnsafe(iso);

const setup = Effect.gen(function* () {
  yield* resetDb;
  const categories = yield* CategoriesService;
  const budgets = yield* BudgetsService;
  const food = yield* categories.create({
    name: "Food",
    color: "#112233",
    icon: null,
  });
  const { period } = yield* budgets.createPeriod({
    name: "July",
    startDate: "2026-07-01",
    endDate: "2026-07-31",
    incomeMinor: 500_000,
    envelopes: [{ categoryId: food.id, plannedMinor: 100_000 }],
  });
  const ann = yield* insertUser("ann@example.com");
  const bob = yield* insertUser("bob@example.com");
  return {
    contributions: yield* ContributionsService,
    period,
    ann: ann.id as UserId,
    bob: bob.id as UserId,
  };
});

const payment = (amountMinor: number, day: string, external = false) => ({
  amountMinor,
  contributedAt: at(`2026-07-${day}T10:00:00Z`),
  note: null,
  ...(external ? { external: true } : {}),
});

layer(TestLayer)("ContributionsService", (it) => {
  it.effect("records who paid in, and lists the newest first", () =>
    Effect.gen(function* () {
      const { contributions, period, ann, bob } = yield* setup;

      yield* contributions.add(period.id, payment(300_000, "02"), ann);
      yield* contributions.add(period.id, payment(200_000, "05"), bob);
      const gift = yield* contributions.add(
        period.id,
        payment(50_000, "03", true),
        ann,
      );
      assert.strictEqual(gift.userId, null);

      const list = yield* contributions.listForPeriod(period.id);
      assert.deepStrictEqual(
        list.map((c) => [c.userId, c.amountMinor]),
        [
          [bob, 200_000],
          [null, 50_000],
          [ann, 300_000],
        ],
      );
    }),
  );

  it.effect("the totals show up next to the planned income", () =>
    Effect.gen(function* () {
      const { contributions, period, ann, bob } = yield* setup;
      const expenses = yield* ExpensesService;
      yield* contributions.add(period.id, payment(300_000, "02"), ann);
      yield* contributions.add(period.id, payment(150_000, "05"), bob);

      const progress = yield* expenses.progress(period.id);
      assert.strictEqual(progress.incomeMinor, 500_000);
      assert.strictEqual(progress.contributedMinor, 450_000);
      const [summary] = yield* expenses.periodSummaries;
      assert.strictEqual(summary?.contributedMinor, 450_000);
    }),
  );

  it.effect("a period nobody paid into has nothing contributed", () =>
    Effect.gen(function* () {
      const { period } = yield* setup;
      const expenses = yield* ExpensesService;
      assert.strictEqual(
        (yield* expenses.progress(period.id)).contributedMinor,
        0,
      );
    }),
  );

  it.effect(
    "whoever paid in deletes it, and so does an owner, nobody else",
    () =>
      Effect.gen(function* () {
        const { contributions, period, ann, bob } = yield* setup;
        const mine = yield* contributions.add(
          period.id,
          payment(100, "02"),
          ann,
        );
        const theirs = yield* contributions.add(
          period.id,
          payment(200, "03"),
          ann,
        );
        const gift = yield* contributions.add(
          period.id,
          payment(300, "04", true),
          ann,
        );

        // another member may delete neither theirs nor money from outside
        assert.instanceOf(
          yield* contributions
            .remove(theirs.id, bob, "member")
            .pipe(Effect.flip),
          Forbidden,
        );
        assert.instanceOf(
          yield* contributions.remove(gift.id, ann, "member").pipe(Effect.flip),
          Forbidden,
        );
        yield* contributions.remove(mine.id, ann, "member");
        yield* contributions.remove(theirs.id, bob, "owner");
        yield* contributions.remove(gift.id, bob, "owner");
        assert.deepStrictEqual(
          yield* contributions.listForPeriod(period.id),
          [],
        );
        assert.instanceOf(
          yield* contributions.remove(mine.id, ann, "owner").pipe(Effect.flip),
          ContributionNotFound,
        );
      }),
  );

  it.effect("belong to a period of the space, and go with it", () =>
    Effect.gen(function* () {
      const { contributions, period, ann } = yield* setup;
      const budgets = yield* BudgetsService;
      const unknown = PeriodId.make("019845e1-682f-4b02-a706-3b2422d13aec");
      assert.instanceOf(
        yield* contributions
          .add(unknown, payment(100, "02"), ann)
          .pipe(Effect.flip),
        PeriodNotFound,
      );
      assert.instanceOf(
        yield* contributions.listForPeriod(unknown).pipe(Effect.flip),
        PeriodNotFound,
      );
      assert.instanceOf(
        yield* contributions
          .remove(
            ContributionId.make("019845e1-682f-4b02-a706-3b2422d13aec"),
            ann,
            "owner",
          )
          .pipe(Effect.flip),
        ContributionNotFound,
      );

      yield* contributions.add(period.id, payment(100, "02"), ann);
      yield* budgets.deletePeriod(period.id);
      assert.strictEqual((yield* contributions.totalByPeriod).size, 0);
    }),
  );
});
