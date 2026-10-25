import {
  EnvelopeId,
  EnvelopeNotFound,
  ExpenseId,
  ExpenseNotFound,
  PeriodId,
  PeriodNotFound,
} from "@bida/api-contract";
import { assert, layer } from "@effect/vitest";
import { DateTime, Effect, Layer } from "effect";
import { SqlClient } from "effect/sql";
import { DbLive } from "../../platform/db.ts";
import { resetDb } from "../../platform/testing.ts";
import { BudgetsModule, BudgetsService } from "../budgets/budgets.module.ts";
import {
  CategoriesModule,
  CategoriesService,
} from "../categories/categories.module.ts";
import { ExpensesModule, ExpensesService } from "./expenses.module.ts";

// Real services on the test database: foreign keys, cascades and aggregates
// are the point of these tests.
const TestLayer = Layer.mergeAll(
  ExpensesModule,
  BudgetsModule,
  CategoriesModule,
).pipe(Layer.provideMerge(DbLive));

const at = (iso: string) => DateTime.makeUnsafe(iso);

/** A period with a "Food" envelope (100.00) and a "Rent" one (200.00). */
const setup = Effect.gen(function* () {
  yield* resetDb;
  const categories = yield* CategoriesService;
  const budgets = yield* BudgetsService;
  const food = yield* categories.create({
    name: "Food",
    color: "#112233",
    icon: null,
  });
  const rent = yield* categories.create({
    name: "Rent",
    color: "#445566",
    icon: null,
  });
  const detail = yield* budgets.createPeriod({
    name: "July",
    startDate: "2026-07-01",
    endDate: "2026-07-31",
    incomeMinor: 500_000,
    envelopes: [
      { categoryId: food.id, plannedMinor: 10_000 },
      { categoryId: rent.id, plannedMinor: 20_000 },
    ],
  });
  const envelopeOf = (categoryId: string) => {
    const envelope = detail.envelopes.find((e) => e.categoryId === categoryId);
    if (envelope === undefined) throw new Error("missing envelope");
    return envelope.id;
  };
  return {
    period: detail.period,
    food,
    rent,
    foodEnvelope: envelopeOf(food.id),
    rentEnvelope: envelopeOf(rent.id),
  };
});

const missingEnvelope = EnvelopeId.make("019845e1-682f-4b02-a706-3b2422d13aec");

layer(TestLayer)("ExpensesService", (it) => {
  it.effect("creates an expense in the period of its envelope", () =>
    Effect.gen(function* () {
      const { period, foodEnvelope } = yield* setup;
      const expenses = yield* ExpensesService;
      const created = yield* expenses.create({
        envelopeId: foodEnvelope,
        amountMinor: 4_599,
        spentAt: at("2026-07-03T10:30:00Z"),
        note: "Biedronka",
      });
      assert.strictEqual(created.periodId, period.id);
      assert.strictEqual(created.amountMinor, 4_599);
      assert.strictEqual(created.note, "Biedronka");
      assert.strictEqual(
        DateTime.formatIso(created.spentAt),
        "2026-07-03T10:30:00.000Z",
      );
      assert.deepStrictEqual(yield* expenses.get(created.id), created);
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("rejects an unknown envelope or expense", () =>
    Effect.gen(function* () {
      yield* setup;
      const expenses = yield* ExpensesService;
      const create = yield* expenses
        .create({
          envelopeId: missingEnvelope,
          amountMinor: 1,
          spentAt: at("2026-07-03T10:30:00Z"),
          note: null,
        })
        .pipe(Effect.flip);
      assert.instanceOf(create, EnvelopeNotFound);

      const unknown = ExpenseId.make("019845e1-682f-4b02-a706-3b2422d13aec");
      assert.instanceOf(
        yield* expenses.get(unknown).pipe(Effect.flip),
        ExpenseNotFound,
      );
      assert.instanceOf(
        yield* expenses.remove(unknown).pipe(Effect.flip),
        ExpenseNotFound,
      );
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("lists newest first and filters", () =>
    Effect.gen(function* () {
      const { period, food, foodEnvelope, rentEnvelope } = yield* setup;
      const expenses = yield* ExpensesService;
      const add = (
        envelopeId: typeof foodEnvelope,
        amountMinor: number,
        iso: string,
      ) =>
        expenses.create({
          envelopeId,
          amountMinor,
          spentAt: at(iso),
          note: null,
        });
      yield* add(foodEnvelope, 100, "2026-07-01T09:00:00Z");
      yield* add(rentEnvelope, 200, "2026-07-05T09:00:00Z");
      yield* add(foodEnvelope, 300, "2026-07-10T09:00:00Z");

      const amounts = (rows: ReadonlyArray<{ amountMinor: number }>) =>
        rows.map((r) => r.amountMinor);

      assert.deepStrictEqual(
        amounts(yield* expenses.listForPeriod(period.id, {})),
        [300, 200, 100],
      );
      assert.deepStrictEqual(
        amounts(
          yield* expenses.listForPeriod(period.id, { categoryId: food.id }),
        ),
        [300, 100],
      );
      assert.deepStrictEqual(
        amounts(
          yield* expenses.listForPeriod(period.id, {
            envelopeId: rentEnvelope,
          }),
        ),
        [200],
      );
      assert.deepStrictEqual(
        amounts(
          yield* expenses.listForPeriod(period.id, {
            from: at("2026-07-05T00:00:00Z"),
            to: at("2026-07-10T09:00:00Z"),
          }),
        ),
        [200],
      );
      assert.deepStrictEqual(
        amounts(
          yield* expenses.listForPeriod(period.id, { limit: 1, offset: 1 }),
        ),
        [200],
      );
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("fails to list for an unknown period", () =>
    Effect.gen(function* () {
      yield* setup;
      const expenses = yield* ExpensesService;
      const error = yield* expenses
        .listForPeriod(
          PeriodId.make("019845e1-682f-4b02-a706-3b2422d13aec"),
          {},
        )
        .pipe(Effect.flip);
      assert.instanceOf(error, PeriodNotFound);
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("updates within a period but not across periods", () =>
    Effect.gen(function* () {
      const { food, foodEnvelope, rentEnvelope } = yield* setup;
      const expenses = yield* ExpensesService;
      const budgets = yield* BudgetsService;
      const created = yield* expenses.create({
        envelopeId: foodEnvelope,
        amountMinor: 100,
        spentAt: at("2026-07-03T10:30:00Z"),
        note: null,
      });

      const moved = yield* expenses.update(created.id, {
        envelopeId: rentEnvelope,
        amountMinor: 250,
        spentAt: at("2026-07-04T08:00:00Z"),
        note: "edited",
      });
      assert.strictEqual(moved.envelopeId, rentEnvelope);
      assert.strictEqual(moved.amountMinor, 250);
      assert.strictEqual(moved.note, "edited");

      // an envelope of another period is not a valid target
      const other = yield* budgets.createPeriod({
        name: "August",
        startDate: "2026-08-01",
        endDate: "2026-08-31",
        incomeMinor: 100,
        envelopes: [],
      });
      const otherEnvelope = yield* budgets.addEnvelope(other.period.id, {
        categoryId: food.id,
        plannedMinor: 0,
      });
      const error = yield* expenses
        .update(created.id, {
          envelopeId: otherEnvelope.id,
          amountMinor: 1,
          spentAt: at("2026-07-04T08:00:00Z"),
          note: null,
        })
        .pipe(Effect.flip);
      assert.instanceOf(error, EnvelopeNotFound);
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("removes an expense", () =>
    Effect.gen(function* () {
      const { period, foodEnvelope } = yield* setup;
      const expenses = yield* ExpensesService;
      const created = yield* expenses.create({
        envelopeId: foodEnvelope,
        amountMinor: 100,
        spentAt: at("2026-07-03T10:30:00Z"),
        note: null,
      });
      yield* expenses.remove(created.id);
      assert.deepStrictEqual(yield* expenses.listForPeriod(period.id, {}), []);
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("reports planned versus spent, including overspending", () =>
    Effect.gen(function* () {
      const { period, foodEnvelope, rentEnvelope } = yield* setup;
      const expenses = yield* ExpensesService;
      const add = (envelopeId: typeof foodEnvelope, amountMinor: number) =>
        expenses.create({
          envelopeId,
          amountMinor,
          spentAt: at("2026-07-03T10:30:00Z"),
          note: null,
        });
      yield* add(foodEnvelope, 7_000);
      yield* add(foodEnvelope, 5_000); // food: 12_000 of 10_000
      // rent has no expenses

      const progress = yield* expenses.progress(period.id);
      assert.strictEqual(progress.incomeMinor, 500_000);
      assert.strictEqual(progress.plannedMinor, 30_000);
      assert.strictEqual(progress.spentMinor, 12_000);
      assert.strictEqual(progress.remainingMinor, 18_000);
      assert.strictEqual(progress.unallocatedMinor, 470_000);

      const byEnvelope = Object.fromEntries(
        progress.envelopes.map((e) => [e.envelopeId, e]),
      );
      assert.strictEqual(byEnvelope[foodEnvelope]?.spentMinor, 12_000);
      assert.strictEqual(byEnvelope[foodEnvelope]?.remainingMinor, -2_000);
      assert.strictEqual(byEnvelope[rentEnvelope]?.spentMinor, 0);
      assert.strictEqual(byEnvelope[rentEnvelope]?.remainingMinor, 20_000);
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect(
    "keeps an envelope with expenses at zero instead of deleting it",
    () =>
      Effect.gen(function* () {
        const { period, food, foodEnvelope } = yield* setup;
        const expenses = yield* ExpensesService;
        const budgets = yield* BudgetsService;
        yield* expenses.create({
          envelopeId: foodEnvelope,
          amountMinor: 100,
          spentAt: at("2026-07-03T10:30:00Z"),
          note: null,
        });
        const updated = yield* budgets.setPlan(period.id, {
          incomeMinor: 500_000,
          envelopes: [{ categoryId: food.id, plannedMinor: 0 }],
        });
        const food0 = updated.envelopes.find((e) => e.categoryId === food.id);
        assert.strictEqual(food0?.plannedMinor, 0);
        assert.strictEqual(
          (yield* expenses.listForPeriod(period.id, {})).length,
          1,
        );
      }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("deleting a period removes its expenses", () =>
    Effect.gen(function* () {
      const { period, foodEnvelope } = yield* setup;
      const sql = yield* SqlClient.SqlClient;
      const expenses = yield* ExpensesService;
      const budgets = yield* BudgetsService;
      yield* expenses.create({
        envelopeId: foodEnvelope,
        amountMinor: 100,
        spentAt: at("2026-07-03T10:30:00Z"),
        note: null,
      });
      yield* budgets.deletePeriod(period.id);
      assert.deepStrictEqual(yield* sql`SELECT id FROM expenses`, []);
      assert.deepStrictEqual(yield* sql`SELECT id FROM envelopes`, []);
    }).pipe(Effect.provide(TestLayer)),
  );
});
