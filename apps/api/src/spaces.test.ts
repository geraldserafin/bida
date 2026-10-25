import {
  CategoryNotFound,
  CurrentSpace,
  DEFAULT_SPACE_ID,
  PeriodId,
  PeriodNotFound,
  type Space,
  SpaceId,
  SpaceNotFound,
} from "@bida/api-contract";
import { assert, layer } from "@effect/vitest";
import { DateTime, Effect, Layer } from "effect";
import {
  BudgetsModule,
  BudgetsService,
} from "./modules/budgets/budgets.module.ts";
import {
  CategoriesModule,
  CategoriesService,
} from "./modules/categories/categories.module.ts";
import {
  ExpensesModule,
  ExpensesService,
} from "./modules/expenses/expenses.module.ts";
import {
  RecurringModule,
  RecurringService,
} from "./modules/recurring/recurring.module.ts";
import { SpacesModule, SpacesService } from "./modules/spaces/spaces.module.ts";
import {
  TransferModule,
  TransferService,
} from "./modules/transfer/transfer.module.ts";
import { DbLive } from "./platform/db.ts";
import { resetDb, TestSpace } from "./platform/testing.ts";

// Every space is a separate budget: what is created in one is invisible in
// another. Tested across modules on the real database.
const TestLayer = Layer.mergeAll(
  SpacesModule,
  TransferModule,
  RecurringModule,
  ExpensesModule,
  BudgetsModule,
  CategoriesModule,
).pipe(Layer.provideMerge(DbLive), Layer.provideMerge(TestSpace()));

/** Runs an effect as a request in the given space. */
const inSpace = <A, E, R>(space: Space, effect: Effect.Effect<A, E, R>) =>
  Effect.provideService(effect, CurrentSpace, space);

const newSpace = Effect.fn("newSpace")(function* (
  name: string,
  defaultCurrency: "PLN" | "EUR" = "PLN",
) {
  const spaces = yield* SpacesService;
  return yield* spaces.create({ name, defaultCurrency });
});

/** A category, a period with an envelope and an expense. */
const fill = Effect.fn("fill")(function* (name: string) {
  const categories = yield* CategoriesService;
  const budgets = yield* BudgetsService;
  const expenses = yield* ExpensesService;
  const category = yield* categories.create({
    name,
    color: "#112233",
    icon: null,
  });
  const period = yield* budgets.createPeriod({
    name: `${name} period`,
    startDate: "2026-07-01",
    endDate: "2026-07-31",
    incomeMinor: 100_000,
    envelopes: [{ categoryId: category.id, plannedMinor: 10_000 }],
  });
  const expense = yield* expenses.create({
    envelopeId: period.envelopes[0]!.id,
    amountMinor: 1_000,
    spentAt: DateTime.makeUnsafe("2026-07-03T10:00:00Z"),
    note: null,
  });
  return { category, period, expense };
});

layer(TestLayer)("spaces", (it) => {
  it.effect("creates, lists, edits and resolves spaces", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const spaces = yield* SpacesService;

      const initial = yield* spaces.list;
      assert.deepStrictEqual(
        initial.map((s) => s.id),
        [DEFAULT_SPACE_ID],
      );

      const home = yield* newSpace("Home", "EUR");
      assert.strictEqual(home.defaultCurrency, "EUR");
      assert.strictEqual((yield* spaces.list).length, 2);

      const renamed = yield* spaces.update(home.id, {
        name: "Flat",
        defaultCurrency: "PLN",
      });
      assert.strictEqual(renamed.name, "Flat");
      assert.strictEqual(renamed.defaultCurrency, "PLN");

      // no id means the default space
      assert.strictEqual(
        (yield* spaces.resolve(undefined)).id,
        DEFAULT_SPACE_ID,
      );
      assert.strictEqual((yield* spaces.resolve(home.id)).id, home.id);
      const unknown = SpaceId.make("019845e1-682f-4b02-a706-3b2422d13aec");
      assert.instanceOf(
        yield* spaces.resolve(unknown).pipe(Effect.flip),
        SpaceNotFound,
      );
      assert.instanceOf(
        yield* spaces
          .update(unknown, { name: "x", defaultCurrency: "PLN" })
          .pipe(Effect.flip),
        SpaceNotFound,
      );
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("data of one space is invisible in another", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const home = yield* newSpace("Home");
      const categories = yield* CategoriesService;
      const budgets = yield* BudgetsService;
      const expenses = yield* ExpensesService;
      const recurring = yield* RecurringService;

      const mine = yield* fill("Mine");
      const other = yield* inSpace(home, fill("Theirs"));

      // lists only show their own
      assert.deepStrictEqual(
        (yield* categories.list).map((c) => c.name),
        ["Mine"],
      );
      assert.deepStrictEqual(
        (yield* inSpace(home, categories.list)).map((c) => c.name),
        ["Theirs"],
      );
      assert.deepStrictEqual(
        (yield* budgets.listPeriods).map((p) => p.name),
        ["Mine period"],
      );

      // looking up the other space's ids finds nothing
      assert.instanceOf(
        yield* categories.get(other.category.id).pipe(Effect.flip),
        CategoryNotFound,
      );
      assert.instanceOf(
        yield* budgets.getPeriod(other.period.period.id).pipe(Effect.flip),
        PeriodNotFound,
      );
      assert.isTrue(
        (yield* expenses.get(other.expense.id).pipe(Effect.flip))._tag ===
          "ExpenseNotFound",
      );
      assert.instanceOf(
        yield* expenses
          .listForPeriod(other.period.period.id, {})
          .pipe(Effect.flip),
        PeriodNotFound,
      );
      assert.instanceOf(
        yield* budgets
          .createPeriod({
            name: "x",
            startDate: "2026-07-01",
            endDate: "2026-07-31",
            incomeMinor: 1,
            envelopes: [{ categoryId: other.category.id, plannedMinor: 5 }],
          })
          .pipe(Effect.flip),
        CategoryNotFound,
      );
      assert.deepStrictEqual(yield* recurring.list, []);

      // writes do not leak either: removing here leaves the other space alone
      yield* budgets.deletePeriod(mine.period.period.id);
      assert.strictEqual((yield* inSpace(home, budgets.listPeriods)).length, 1);
      assert.instanceOf(
        yield* categories
          .update(other.category.id, {
            name: "x",
            color: "#000000",
            icon: null,
          })
          .pipe(Effect.flip),
        CategoryNotFound,
      );
      assert.strictEqual(
        (yield* inSpace(home, categories.get(other.category.id))).name,
        "Theirs",
      );
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("the same names can be used in different spaces", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const home = yield* newSpace("Home");
      const categories = yield* CategoriesService;
      yield* categories.create({ name: "Food", color: "#112233", icon: null });
      yield* inSpace(
        home,
        categories.create({ name: "Food", color: "#112233", icon: null }),
      );
      assert.strictEqual((yield* categories.list).length, 1);
      assert.strictEqual((yield* inSpace(home, categories.list)).length, 1);
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("new periods and rules take the currency of their space", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const euro = yield* newSpace("Berlin", "EUR");
      const budgets = yield* BudgetsService;
      const recurring = yield* RecurringService;
      const categories = yield* CategoriesService;

      const inEuro = yield* inSpace(
        euro,
        Effect.gen(function* () {
          const category = yield* categories.create({
            name: "Rent",
            color: "#112233",
            icon: null,
          });
          const period = yield* budgets.createPeriod({
            name: "July",
            startDate: "2026-07-01",
            endDate: "2026-07-31",
            incomeMinor: 1,
            envelopes: [],
          });
          const rule = yield* recurring.create({
            categoryId: category.id,
            amountMinor: 100,
            frequency: "monthly",
            note: null,
            active: true,
          });
          const suggested = yield* recurring.suggestedPlan();
          return { period, rule, suggested };
        }),
      );
      assert.strictEqual(inEuro.period.period.currency, "EUR");
      assert.strictEqual(inEuro.rule.currency, "EUR");
      assert.strictEqual(inEuro.suggested.length, 1);

      // the default space still defaults to PLN, and an explicit currency wins
      const pln = yield* budgets.createPeriod({
        name: "July",
        startDate: "2026-07-01",
        endDate: "2026-07-31",
        incomeMinor: 1,
        envelopes: [],
      });
      assert.strictEqual(pln.period.currency, "PLN");
      const explicit = yield* inSpace(
        euro,
        budgets.createPeriod({
          name: "Aug",
          startDate: "2026-08-01",
          endDate: "2026-08-31",
          incomeMinor: 1,
          currency: "USD",
          envelopes: [],
        }),
      );
      assert.strictEqual(explicit.period.currency, "USD");
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("export and import only touch their own space", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const home = yield* newSpace("Home");
      const transfer = yield* TransferService;
      yield* fill("Mine");
      yield* inSpace(home, fill("Theirs"));

      const mine = yield* transfer.export;
      assert.deepStrictEqual(
        mine.categories.map((c) => c.name),
        ["Mine"],
      );
      assert.deepStrictEqual(
        (yield* inSpace(home, transfer.export)).categories.map((c) => c.name),
        ["Theirs"],
      );
      assert.strictEqual(
        (yield* transfer.previewImport(mine)).current.expenses,
        1,
      );

      // replacing my data leaves the other space alone
      yield* transfer.importDocument({
        ...mine,
        categories: [],
        periods: [],
        envelopes: [],
        expenses: [],
        recurringRules: [],
      });
      assert.deepStrictEqual((yield* transfer.export).categories, []);
      assert.strictEqual(
        (yield* inSpace(home, transfer.export)).expenses.length,
        1,
      );

      // and the CSV is per space too
      assert.strictEqual(
        (yield* inSpace(home, transfer.exportCsv)).trimEnd().split("\n").length,
        2,
      );
      assert.strictEqual(
        (yield* transfer.exportCsv).trimEnd().split("\n").length,
        1,
      );
    }).pipe(Effect.provide(TestLayer)),
  );
});

layer(TestLayer)("request hardening", (it) => {
  it.effect("a header that is not a uuid is just an unknown space", () =>
    Effect.gen(function* () {
      const spaces = yield* SpacesService;
      const error = yield* spaces.resolve("abc").pipe(Effect.flip);
      assert.instanceOf(error, SpaceNotFound);
      assert.strictEqual(error.id, "abc");
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("a period can be renamed and moved, but not turned around", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const budgets = yield* BudgetsService;
      const created = yield* budgets.createPeriod({
        name: "July",
        startDate: "2026-07-01",
        endDate: "2026-07-31",
        incomeMinor: 500,
        envelopes: [],
      });
      const updated = yield* budgets.updatePeriod(created.period.id, {
        name: "Summer",
        startDate: "2026-07-05",
        endDate: "2026-08-04",
      });
      assert.strictEqual(updated.period.name, "Summer");
      assert.strictEqual(updated.period.startDate, "2026-07-05");
      assert.strictEqual(updated.period.endDate, "2026-08-04");
      // money and currency are not part of it
      assert.strictEqual(updated.period.incomeMinor, 500);
      assert.strictEqual(updated.period.currency, "PLN");

      const reversed = yield* budgets
        .updatePeriod(created.period.id, {
          name: "x",
          startDate: "2026-08-01",
          endDate: "2026-07-01",
        })
        .pipe(Effect.flip);
      assert.strictEqual(reversed._tag, "InvalidPeriodRange");

      const missing = yield* budgets
        .updatePeriod(PeriodId.make("019845e1-682f-4b02-a706-3b2422d13aec"), {
          name: "x",
          startDate: "2026-07-01",
          endDate: "2026-07-02",
        })
        .pipe(Effect.flip);
      assert.instanceOf(missing, PeriodNotFound);
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect(
    "applying recurring rules twice at once adds each expense once",
    () =>
      Effect.gen(function* () {
        yield* resetDb;
        const budgets = yield* BudgetsService;
        const categories = yield* CategoriesService;
        const recurring = yield* RecurringService;
        const expenses = yield* ExpensesService;
        const rent = yield* categories.create({
          name: "Rent",
          color: "#112233",
          icon: null,
        });
        for (const amountMinor of [100, 200, 300]) {
          yield* recurring.create({
            categoryId: rent.id,
            amountMinor,
            frequency: "monthly",
            note: null,
            active: true,
          });
        }
        const period = yield* budgets.createPeriod({
          name: "July",
          startDate: "2026-07-01",
          endDate: "2026-07-31",
          incomeMinor: 1_000,
          envelopes: [],
        });

        // none of the concurrent calls may fail on the unique index
        const results = yield* Effect.all(
          Array.from({ length: 4 }, () =>
            recurring.applyToPeriod(period.period.id),
          ),
          { concurrency: "unbounded" },
        );
        assert.strictEqual(
          results.reduce((sum, r) => sum + r.added, 0),
          3,
        );
        assert.strictEqual(
          (yield* expenses.listForPeriod(period.period.id, {})).length,
          3,
        );
      }).pipe(Effect.provide(TestLayer)),
  );

  it.effect(
    "a legacy backup the API would not accept is refused, not a crash",
    () =>
      Effect.gen(function* () {
        yield* resetDb;
        const transfer = yield* TransferService;
        const error = yield* transfer
          .importLegacy({
            backup: {
              version: 1,
              data: {
                categories: [
                  {
                    id: 1,
                    name: "n".repeat(500),
                    color: "#22C55E",
                    icon: null,
                  },
                ],
                periods: [],
                splits: [],
                recurring_rules: [],
                expenses: [],
              },
            },
          })
          .pipe(Effect.flip);
        assert.strictEqual(error._tag, "InvalidImport");
      }).pipe(Effect.provide(TestLayer)),
  );
});
