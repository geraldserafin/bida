import {
  type CategoryId,
  CategoryNotFound,
  PeriodId,
  PeriodNotFound,
  RecurringRuleId,
  RecurringRuleNotFound,
} from "@bida/api-contract";
import { assert, layer } from "@effect/vitest";
import { Effect, Layer } from "effect";
import { SqlClient } from "effect/sql";
import { DbLive } from "../../platform/db.ts";
import { resetDb, TestSpace } from "../../platform/testing.ts";
import { BudgetsModule, BudgetsService } from "../budgets/budgets.module.ts";
import {
  CategoriesModule,
  CategoriesService,
} from "../categories/categories.module.ts";
import {
  ExpensesModule,
  ExpensesService,
} from "../expenses/expenses.module.ts";
import { RecurringModule, RecurringService } from "./recurring.module.ts";

// Real services on the test database: the apply rules rely on SQL behaviour
// (transactions, unique index, ON DELETE SET NULL).
const TestLayer = Layer.mergeAll(
  RecurringModule,
  ExpensesModule,
  BudgetsModule,
  CategoriesModule,
).pipe(Layer.provideMerge(DbLive), Layer.provideMerge(TestSpace()));

const unknownId = "019845e1-682f-4b02-a706-3b2422d13aec";

const category = Effect.fn("category")(function* (name: string) {
  const categories = yield* CategoriesService;
  return (yield* categories.create({ name, color: "#112233", icon: null })).id;
});

const rule = (
  categoryId: CategoryId,
  amountMinor: number,
  extra: { note?: string; active?: boolean } = {},
) => ({
  categoryId,
  amountMinor,
  frequency: "monthly" as const,
  note: extra.note ?? null,
  active: extra.active ?? true,
});

const newPeriod = Effect.fn("newPeriod")(function* (
  envelopes: ReadonlyArray<{
    categoryId: CategoryId;
    plannedMinor: number;
  }> = [],
) {
  const budgets = yield* BudgetsService;
  return yield* budgets.createPeriod({
    name: "July",
    startDate: "2026-07-01",
    endDate: "2026-07-31",
    incomeMinor: 1_000_000,
    envelopes,
  });
});

layer(TestLayer)("RecurringService", (it) => {
  it.effect("creates, lists, edits and deletes rules", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const recurring = yield* RecurringService;
      const rent = yield* category("Rent");

      const created = yield* recurring.create(
        rule(rent, 200_000, { note: "Rent" }),
      );
      assert.strictEqual(created.amountMinor, 200_000);
      assert.strictEqual(created.frequency, "monthly");
      assert.isTrue(created.active);
      assert.deepStrictEqual(yield* recurring.list, [created]);

      const edited = yield* recurring.update(created.id, {
        ...rule(rent, 210_000, { note: "Rent", active: false }),
        frequency: "weekly",
      });
      assert.strictEqual(edited.id, created.id);
      assert.strictEqual(edited.amountMinor, 210_000);
      assert.strictEqual(edited.frequency, "weekly");
      assert.isFalse(edited.active);

      yield* recurring.remove(created.id);
      assert.deepStrictEqual(yield* recurring.list, []);
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("rejects unknown categories and rules", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const recurring = yield* RecurringService;
      const rent = yield* category("Rent");
      const ghost = unknownId as CategoryId;

      assert.instanceOf(
        yield* recurring.create(rule(ghost, 100)).pipe(Effect.flip),
        CategoryNotFound,
      );
      const id = RecurringRuleId.make(unknownId);
      assert.instanceOf(
        yield* recurring.update(id, rule(rent, 100)).pipe(Effect.flip),
        RecurringRuleNotFound,
      );
      assert.instanceOf(
        yield* recurring.update(id, rule(ghost, 100)).pipe(Effect.flip),
        CategoryNotFound,
      );
      assert.instanceOf(
        yield* recurring.remove(id).pipe(Effect.flip),
        RecurringRuleNotFound,
      );
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("suggests a plan from the active rules, summed per category", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const recurring = yield* RecurringService;
      const rent = yield* category("Rent");
      const gym = yield* category("Gym");
      yield* recurring.create(rule(rent, 200_000));
      yield* recurring.create(rule(rent, 5_000));
      yield* recurring.create(rule(gym, 12_000));
      yield* recurring.create(rule(gym, 99_000, { active: false }));

      const plan = Object.fromEntries(
        (yield* recurring.suggestedPlan()).map((p) => [
          p.categoryId,
          p.plannedMinor,
        ]),
      );
      assert.deepStrictEqual(plan, { [rent]: 205_000, [gym]: 12_000 });
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("apply adds expenses, creating missing envelopes", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const recurring = yield* RecurringService;
      const expenses = yield* ExpensesService;
      const budgets = yield* BudgetsService;
      const rent = yield* category("Rent");
      const gym = yield* category("Gym");
      const paused = yield* category("Paused");
      // rent already has an envelope with its own plan, gym has none
      const period = yield* newPeriod([
        { categoryId: rent, plannedMinor: 250_000 },
      ]);

      const rentRule = yield* recurring.create(
        rule(rent, 200_000, { note: "Rent" }),
      );
      const gymRule = yield* recurring.create(rule(gym, 12_000));
      yield* recurring.create(rule(paused, 1_000, { active: false }));

      const result = yield* recurring.applyToPeriod(period.period.id);
      assert.strictEqual(result.added, 2);

      const detail = yield* budgets.getPeriod(period.period.id);
      const planned = Object.fromEntries(
        detail.envelopes.map((e) => [e.categoryId, e.plannedMinor]),
      );
      // existing envelope untouched, missing one planned with the rule amount
      assert.deepStrictEqual(planned, { [rent]: 250_000, [gym]: 12_000 });

      const listed = yield* expenses.listForPeriod(period.period.id, {});
      assert.strictEqual(listed.length, 2);
      const byRule = Object.fromEntries(listed.map((e) => [e.recurringId, e]));
      assert.strictEqual(byRule[rentRule.id]?.amountMinor, 200_000);
      assert.strictEqual(byRule[rentRule.id]?.note, "Rent");
      assert.strictEqual(byRule[gymRule.id]?.amountMinor, 12_000);
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("apply is idempotent and picks up rules added later", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const recurring = yield* RecurringService;
      const expenses = yield* ExpensesService;
      const rent = yield* category("Rent");
      const period = yield* newPeriod();
      yield* recurring.create(rule(rent, 200_000));

      assert.strictEqual(
        (yield* recurring.applyToPeriod(period.period.id)).added,
        1,
      );
      assert.strictEqual(
        (yield* recurring.applyToPeriod(period.period.id)).added,
        0,
      );

      yield* recurring.create(rule(rent, 5_000));
      assert.strictEqual(
        (yield* recurring.applyToPeriod(period.period.id)).added,
        1,
      );
      assert.strictEqual(
        (yield* expenses.listForPeriod(period.period.id, {})).length,
        2,
      );
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("a rule applies once per period", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const recurring = yield* RecurringService;
      const rent = yield* category("Rent");
      const july = yield* newPeriod();
      const budgets = yield* BudgetsService;
      const august = yield* budgets.createPeriod({
        name: "August",
        startDate: "2026-08-01",
        endDate: "2026-08-31",
        incomeMinor: 1,
        envelopes: [],
      });
      yield* recurring.create(rule(rent, 200_000));

      assert.strictEqual(
        (yield* recurring.applyToPeriod(july.period.id)).added,
        1,
      );
      assert.strictEqual(
        (yield* recurring.applyToPeriod(august.period.id)).added,
        1,
      );
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("apply fails for an unknown period", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const recurring = yield* RecurringService;
      const error = yield* recurring
        .applyToPeriod(PeriodId.make(unknownId))
        .pipe(Effect.flip);
      assert.instanceOf(error, PeriodNotFound);
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("deleting a rule keeps the expenses it generated", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const recurring = yield* RecurringService;
      const expenses = yield* ExpensesService;
      const rent = yield* category("Rent");
      const period = yield* newPeriod();
      const created = yield* recurring.create(rule(rent, 200_000));
      yield* recurring.applyToPeriod(period.period.id);

      yield* recurring.remove(created.id);
      const listed = yield* expenses.listForPeriod(period.period.id, {});
      assert.strictEqual(listed.length, 1);
      assert.isNull(listed[0]?.recurringId);
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect(
    "the database refuses a second expense of the same rule in a period",
    () =>
      Effect.gen(function* () {
        yield* resetDb;
        const recurring = yield* RecurringService;
        const expenses = yield* ExpensesService;
        const sql = yield* SqlClient.SqlClient;
        const rent = yield* category("Rent");
        const period = yield* newPeriod();
        const created = yield* recurring.create(rule(rent, 200_000));
        yield* recurring.applyToPeriod(period.period.id);
        const [existing] = yield* expenses.listForPeriod(period.period.id, {});

        // a concurrent apply that slipped past the in-memory check
        const duplicate = yield* sql`
        INSERT INTO expenses (id, period_id, envelope_id, amount_minor, spent_at,
          recurring_id, created_at, updated_at)
        VALUES (gen_random_uuid(), ${period.period.id}, ${existing?.envelopeId},
          1, now(), ${created.id}, now(), now())
      `.pipe(Effect.flip);
        assert.strictEqual(duplicate._tag, "SqlError");
      }).pipe(Effect.provide(TestLayer)),
  );
});
