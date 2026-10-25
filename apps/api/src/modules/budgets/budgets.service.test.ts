import {
  type CategoryId,
  CategoryNotFound,
  EnvelopeAlreadyExists,
  InvalidPeriodRange,
  NoPeriods,
  PeriodId,
  PeriodNotFound,
} from "@bida/api-contract";
import { assert, layer } from "@effect/vitest";
import { Effect, Layer } from "effect";
import { SqlClient } from "effect/sql";
import { DbLive } from "../../platform/db.ts";
import { resetDb, TestSpace } from "../../platform/testing.ts";
import {
  CategoriesModule,
  CategoriesService,
} from "../categories/categories.module.ts";
import { BudgetsModule, BudgetsService } from "./budgets.module.ts";

// Real services on the test database: the rules here depend on SQL behaviour
// (transactions, foreign keys, unique constraints).
const TestLayer = Layer.mergeAll(BudgetsModule, CategoriesModule).pipe(
  Layer.provideMerge(DbLive),
  Layer.provideMerge(TestSpace()),
);

const missing = PeriodId.make("019845e1-682f-4b02-a706-3b2422d13aec");

const clean = Effect.gen(function* () {
  const sql = yield* SqlClient.SqlClient;
  yield* sql`DROP TABLE IF EXISTS envelope_refs`;
  yield* resetDb;
});

const category = Effect.fn("category")(function* (name: string) {
  const categories = yield* CategoriesService;
  const created = yield* categories.create({
    name,
    color: "#112233",
    icon: null,
  });
  return created.id;
});

const july = {
  name: "July",
  startDate: "2026-07-01",
  endDate: "2026-07-31",
};

layer(TestLayer)("BudgetsService", (it) => {
  it.effect("creates a period with its envelopes and totals", () =>
    Effect.gen(function* () {
      yield* clean;
      const budgets = yield* BudgetsService;
      const food = yield* category("Food");
      const rent = yield* category("Rent");
      const fun = yield* category("Fun");

      const created = yield* budgets.createPeriod({
        ...july,
        incomeMinor: 500_000,
        envelopes: [
          { categoryId: food, plannedMinor: 120_000 },
          { categoryId: rent, plannedMinor: 200_000 },
          { categoryId: fun, plannedMinor: 0 },
        ],
      });

      assert.strictEqual(created.period.startDate, "2026-07-01");
      assert.strictEqual(created.period.incomeMinor, 500_000);
      assert.strictEqual(created.envelopes.length, 2); // zero amount skipped
      assert.strictEqual(created.plannedMinor, 320_000);
      assert.strictEqual(created.unallocatedMinor, 180_000);
      assert.deepStrictEqual(
        yield* budgets.getPeriod(created.period.id),
        created,
      );
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("reports a negative unallocated amount when over-allocated", () =>
    Effect.gen(function* () {
      yield* clean;
      const budgets = yield* BudgetsService;
      const food = yield* category("Food");
      const created = yield* budgets.createPeriod({
        ...july,
        incomeMinor: 100,
        envelopes: [{ categoryId: food, plannedMinor: 150 }],
      });
      assert.strictEqual(created.unallocatedMinor, -50);
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("rejects an inverted date range and unknown categories", () =>
    Effect.gen(function* () {
      yield* clean;
      const budgets = yield* BudgetsService;
      const range = yield* budgets
        .createPeriod({
          name: "x",
          startDate: "2026-07-31",
          endDate: "2026-07-01",
          incomeMinor: 1,
          envelopes: [],
        })
        .pipe(Effect.flip);
      assert.instanceOf(range, InvalidPeriodRange);

      const unknown = yield* budgets
        .createPeriod({
          ...july,
          incomeMinor: 1,
          envelopes: [
            {
              categoryId: "00000000-0000-4000-8000-000000000000" as CategoryId,
              plannedMinor: 5,
            },
          ],
        })
        .pipe(Effect.flip);
      assert.instanceOf(unknown, CategoryNotFound);
      assert.deepStrictEqual(yield* budgets.listPeriods, []);
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("lists newest first and finds the current period", () =>
    Effect.gen(function* () {
      yield* clean;
      const budgets = yield* BudgetsService;
      const none = yield* budgets.currentPeriod.pipe(Effect.flip);
      assert.instanceOf(none, NoPeriods);

      yield* budgets.createPeriod({
        name: "June",
        startDate: "2026-06-01",
        endDate: "2026-06-30",
        incomeMinor: 1,
        envelopes: [],
      });
      yield* budgets.createPeriod({ ...july, incomeMinor: 2, envelopes: [] });

      const periods = yield* budgets.listPeriods;
      assert.deepStrictEqual(
        periods.map((p) => p.name),
        ["July", "June"],
      );
      assert.strictEqual((yield* budgets.currentPeriod).period.name, "July");
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("setPlan creates, updates and removes envelopes", () =>
    Effect.gen(function* () {
      yield* clean;
      const budgets = yield* BudgetsService;
      const food = yield* category("Food");
      const rent = yield* category("Rent");
      const fun = yield* category("Fun");
      const untouched = yield* category("Untouched");
      const created = yield* budgets.createPeriod({
        ...july,
        incomeMinor: 500_000,
        envelopes: [
          { categoryId: food, plannedMinor: 120_000 },
          { categoryId: rent, plannedMinor: 200_000 },
          { categoryId: untouched, plannedMinor: 10_000 },
        ],
      });

      const updated = yield* budgets.setPlan(created.period.id, {
        version: created.period.version,
        incomeMinor: 450_000,
        envelopes: [
          { categoryId: food, plannedMinor: 90_000 },
          { categoryId: rent, plannedMinor: 0 },
          { categoryId: fun, plannedMinor: 30_000 },
        ],
      });

      assert.strictEqual(updated.period.incomeMinor, 450_000);
      const planned = Object.fromEntries(
        updated.envelopes.map((e) => [e.categoryId, e.plannedMinor]),
      );
      assert.deepStrictEqual(planned, {
        [food]: 90_000,
        [fun]: 30_000,
        [untouched]: 10_000,
      });
      assert.strictEqual(updated.plannedMinor, 130_000);
      assert.strictEqual(updated.unallocatedMinor, 320_000);
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect(
    "setPlan keeps an envelope at zero when something references it",
    () =>
      Effect.gen(function* () {
        yield* clean;
        const sql = yield* SqlClient.SqlClient;
        const budgets = yield* BudgetsService;
        const food = yield* category("Food");
        const created = yield* budgets.createPeriod({
          ...july,
          incomeMinor: 100,
          envelopes: [{ categoryId: food, plannedMinor: 100 }],
        });
        const envelope = created.envelopes[0];
        assert.isDefined(envelope);

        // stands in for the expenses table that will reference envelopes
        yield* sql`CREATE TABLE envelope_refs (
        envelope_id uuid NOT NULL REFERENCES envelopes (id) ON DELETE RESTRICT
      )`;
        yield* sql`INSERT INTO envelope_refs ${sql.insert({ envelopeId: envelope?.id })}`;

        const updated = yield* budgets
          .setPlan(created.period.id, {
            version: created.period.version,
            incomeMinor: 100,
            envelopes: [{ categoryId: food, plannedMinor: 0 }],
          })
          .pipe(
            Effect.ensuring(
              sql`DROP TABLE IF EXISTS envelope_refs`.pipe(Effect.orDie),
            ),
          );

        assert.strictEqual(updated.envelopes.length, 1);
        assert.strictEqual(updated.envelopes[0]?.plannedMinor, 0);
      }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("addEnvelope adds once per category", () =>
    Effect.gen(function* () {
      yield* clean;
      const budgets = yield* BudgetsService;
      const food = yield* category("Food");
      const created = yield* budgets.createPeriod({
        ...july,
        incomeMinor: 100,
        envelopes: [],
      });
      const envelope = yield* budgets.addEnvelope(created.period.id, {
        categoryId: food,
        plannedMinor: 0,
      });
      assert.strictEqual(envelope.periodId, created.period.id);
      const again = yield* budgets
        .addEnvelope(created.period.id, { categoryId: food, plannedMinor: 5 })
        .pipe(Effect.flip);
      assert.instanceOf(again, EnvelopeAlreadyExists);
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("delete removes the period with its envelopes", () =>
    Effect.gen(function* () {
      yield* clean;
      const sql = yield* SqlClient.SqlClient;
      const budgets = yield* BudgetsService;
      const food = yield* category("Food");
      const created = yield* budgets.createPeriod({
        ...july,
        incomeMinor: 100,
        envelopes: [{ categoryId: food, plannedMinor: 100 }],
      });
      yield* budgets.deletePeriod(created.period.id);
      assert.deepStrictEqual(yield* sql`SELECT id FROM envelopes`, []);
      const error = yield* budgets
        .deletePeriod(created.period.id)
        .pipe(Effect.flip);
      assert.instanceOf(error, PeriodNotFound);
      const getError = yield* budgets.getPeriod(missing).pipe(Effect.flip);
      assert.instanceOf(getError, PeriodNotFound);
    }).pipe(Effect.provide(TestLayer)),
  );
});
