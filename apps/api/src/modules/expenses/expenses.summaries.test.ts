import { assert, layer } from "@effect/vitest";
import { DateTime, Effect, Layer } from "effect";
import { DbLive } from "../../platform/db.ts";
import { resetDb, TestSpace } from "../../platform/testing.ts";
import { BudgetsModule, BudgetsService } from "../budgets/budgets.module.ts";
import {
  CategoriesModule,
  CategoriesService,
} from "../categories/categories.module.ts";
import { ExpensesModule, ExpensesService } from "./expenses.module.ts";

const TestLayer = Layer.mergeAll(
  ExpensesModule,
  BudgetsModule,
  CategoriesModule,
).pipe(Layer.provideMerge(DbLive), Layer.provideMerge(TestSpace()));

layer(TestLayer)("period summaries", (it) => {
  it.effect("lists every period with what is planned and spent", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const categories = yield* CategoriesService;
      const budgets = yield* BudgetsService;
      const expenses = yield* ExpensesService;
      const food = yield* categories.create({
        name: "Food",
        color: "#112233",
        icon: null,
      });

      const july = yield* budgets.createPeriod({
        name: "July",
        startDate: "2026-07-01",
        endDate: "2026-07-31",
        incomeMinor: 500_000,
        envelopes: [{ categoryId: food.id, plannedMinor: 40_000 }],
      });
      // an empty period must show up too, with zeros
      yield* budgets.createPeriod({
        name: "June",
        startDate: "2026-06-01",
        endDate: "2026-06-30",
        incomeMinor: 1,
        envelopes: [],
      });
      for (const amountMinor of [1_000, 2_500]) {
        yield* expenses.create({
          envelopeId: july.envelopes[0]!.id,
          amountMinor,
          spentAt: DateTime.makeUnsafe("2026-07-03T10:00:00Z"),
          note: null,
        });
      }

      const summaries = yield* expenses.periodSummaries;
      assert.deepStrictEqual(
        summaries.map((s) => [s.period.name, s.plannedMinor, s.spentMinor]),
        [
          ["July", 40_000, 3_500],
          ["June", 0, 0],
        ],
      );
    }).pipe(Effect.provide(TestLayer)),
  );
});
