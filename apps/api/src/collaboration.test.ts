import {
  Api,
  CategoryId,
  PeriodChanged,
  type UserId,
} from "@bida/api-contract";
import { assert, layer } from "@effect/vitest";
import { DateTime, Effect, Layer } from "effect";
import { HttpServer } from "effect/http";
import { HttpApiTest } from "effect/http-api";
import { SqlClient } from "effect/sql";
import {
  BudgetsHttp,
  BudgetsModule,
  BudgetsService,
} from "./modules/budgets/budgets.module.ts";
import {
  CategoriesHttp,
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
import {
  TransferHttp,
  TransferModule,
} from "./modules/transfer/transfer.module.ts";
import { DbLive } from "./platform/db.ts";
import {
  defaultSpace,
  insertUser,
  resetDb,
  TestAuthenticated,
  TestSpace,
  TestSpaceContext,
} from "./platform/testing.ts";

const Services = Layer.mergeAll(
  BudgetsModule,
  CategoriesModule,
  ExpensesModule,
  RecurringModule,
  TransferModule,
).pipe(Layer.provideMerge(DbLive));

const HttpFor = (role: "owner" | "member") =>
  Layer.mergeAll(BudgetsHttp, CategoriesHttp, TransferHttp).pipe(
    Layer.provideMerge(Services),
    Layer.provideMerge(TestSpaceContext(defaultSpace, role)),
    Layer.provideMerge(TestSpace()),
    Layer.provideMerge(TestAuthenticated()),
    Layer.provideMerge(HttpServer.layerServices),
  );

const makeClient = HttpApiTest.groups(Api, [
  "periods",
  "categories",
  "transfer",
]);

const start = Effect.gen(function* () {
  yield* resetDb;
  const categories = yield* CategoriesService;
  const budgets = yield* BudgetsService;
  const food = yield* categories.create({
    name: "Food",
    color: "#112233",
    icon: null,
  });
  const created = yield* budgets.createPeriod({
    name: "July",
    startDate: "2026-07-01",
    endDate: "2026-07-31",
    incomeMinor: 100_000,
    envelopes: [{ categoryId: food.id, plannedMinor: 10_000 }],
  });
  return { food, period: created.period, envelope: created.envelopes[0]! };
});

// What members of a shared space may and may not do, through the whole API.
layer(HttpFor("member"))("what a member of a space may do", (it) => {
  it.effect("may work with the budget", () =>
    Effect.gen(function* () {
      const { food, period } = yield* start;
      const client = yield* makeClient;

      const category = yield* client.categories.create({
        payload: { name: "Fun", color: "#445566", icon: null },
      });
      yield* client.categories.update({
        params: { id: category.id },
        payload: { name: "Fun!", color: "#445566", icon: null },
      });
      const plan = yield* client.periods.setPlan({
        params: { id: period.id },
        payload: {
          version: period.version,
          incomeMinor: 120_000,
          envelopes: [{ categoryId: food.id, plannedMinor: 20_000 }],
        },
      });
      assert.strictEqual(plan.period.incomeMinor, 120_000);
    }),
  );

  it.effect("may not delete periods, categories or replace all the data", () =>
    Effect.gen(function* () {
      const { food, period } = yield* start;
      const client = yield* makeClient;

      const deletePeriod = yield* client.periods
        .delete({ params: { id: period.id } })
        .pipe(Effect.flip);
      const deleteCategory = yield* client.categories
        .delete({ params: { id: CategoryId.make(food.id) } })
        .pipe(Effect.flip);
      const replace = yield* client.transfer
        .importLegacy({
          payload: {
            backup: {
              version: 1,
              data: {
                periods: [],
                categories: [],
                recurring_rules: [],
                splits: [],
                expenses: [],
              },
            },
          },
        })
        .pipe(Effect.flip);

      for (const error of [deletePeriod, deleteCategory, replace])
        assert.strictEqual(error._tag, "Forbidden");

      // and nothing was lost
      const budgets = yield* BudgetsService;
      assert.strictEqual((yield* budgets.listPeriods).length, 1);
    }),
  );
});

layer(HttpFor("owner"))("what an owner of a space may do", (it) => {
  it.effect("may delete periods and categories", () =>
    Effect.gen(function* () {
      const { period } = yield* start;
      const client = yield* makeClient;

      yield* client.periods.delete({ params: { id: period.id } });
      const categories = yield* CategoriesService;
      const [food] = yield* categories.list;
      yield* client.categories.delete({ params: { id: food!.id } });
      assert.deepStrictEqual(yield* categories.list, []);
    }),
  );
});

layer(Services.pipe(Layer.provideMerge(TestSpace())))(
  "editing together",
  (it) => {
    it.effect("an edit of the plan on stale data is refused", () =>
      Effect.gen(function* () {
        const { food, period } = yield* start;
        const budgets = yield* BudgetsService;
        const plan = (incomeMinor: number, version: number) => ({
          version,
          incomeMinor,
          envelopes: [{ categoryId: food.id, plannedMinor: 10_000 }],
        });

        // both people loaded version 1
        const first = yield* budgets.setPlan(period.id, plan(110_000, 1));
        assert.strictEqual(first.period.version, 2);
        const stale = yield* budgets
          .setPlan(period.id, plan(130_000, 1))
          .pipe(Effect.flip);
        assert.instanceOf(stale, PeriodChanged);
        // what the first one saved is still there
        assert.strictEqual(
          (yield* budgets.getPeriod(period.id)).period.incomeMinor,
          110_000,
        );
        // after reloading, the second can edit
        const second = yield* budgets.setPlan(period.id, plan(130_000, 2));
        assert.strictEqual(second.period.version, 3);
      }),
    );

    it.effect("renaming a period is checked the same way", () =>
      Effect.gen(function* () {
        const { period } = yield* start;
        const budgets = yield* BudgetsService;
        const rename = (name: string, version: number) => ({
          version,
          name,
          startDate: "2026-07-01",
          endDate: "2026-07-31",
        });

        const renamed = yield* budgets.updatePeriod(period.id, rename("A", 1));
        assert.strictEqual(renamed.period.version, 2);
        assert.instanceOf(
          yield* budgets
            .updatePeriod(period.id, rename("B", 1))
            .pipe(Effect.flip),
          PeriodChanged,
        );
        assert.strictEqual(
          (yield* budgets.getPeriod(period.id)).period.name,
          "A",
        );
      }),
    );

    it.effect("an expense remembers who added it, even after they leave", () =>
      Effect.gen(function* () {
        const { envelope } = yield* start;
        const sql = yield* SqlClient.SqlClient;
        const expenses = yield* ExpensesService;
        const ann = yield* insertUser("ann@example.com");
        const annId = ann.id as UserId;
        const input = {
          envelopeId: envelope.id,
          amountMinor: 100,
          spentAt: DateTime.makeUnsafe("2026-07-03T10:00:00Z"),
          note: null,
        };

        const byAnn = yield* expenses.create(input, annId);
        const nobody = yield* expenses.create(input);
        assert.strictEqual(byAnn.createdBy, annId);
        assert.strictEqual(nobody.createdBy, null);
        assert.strictEqual((yield* expenses.get(byAnn.id)).createdBy, annId);

        // leaving a space changes nothing about what she added; only deleting
        // the account does, and then the expense stays without an author
        yield* sql`DELETE FROM users WHERE id = ${ann.id}`;
        assert.strictEqual((yield* expenses.get(byAnn.id)).createdBy, null);
      }),
    );

    it.effect("rules applied by somebody are added in their name", () =>
      Effect.gen(function* () {
        const { food, period } = yield* start;
        const recurring = yield* RecurringService;
        const expenses = yield* ExpensesService;
        const ann = yield* insertUser("ann@example.com");
        yield* recurring.create({
          categoryId: food.id,
          amountMinor: 500,
          currency: "PLN",
          frequency: "monthly",
          note: null,
          active: true,
        });

        yield* recurring.applyToPeriod(period.id, ann.id as UserId);

        const [added] = yield* expenses.listForPeriod(period.id, {
          limit: 10,
          offset: 0,
        });
        assert.strictEqual(added?.createdBy, ann.id as UserId);
      }),
    );
  },
);
