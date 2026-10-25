import { type CategoryId, exponentOf, InvalidCsv } from "@bida/api-contract";
import { assert, it, layer } from "@effect/vitest";
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
import {
  TransferModule,
  TransferService,
} from "./modules/transfer/transfer.module.ts";
import { DbLive } from "./platform/db.ts";
import { resetDb } from "./platform/testing.ts";

// Currency cuts across modules, so it is tested across them on the real db.
const TestLayer = Layer.mergeAll(
  TransferModule,
  RecurringModule,
  ExpensesModule,
  BudgetsModule,
  CategoriesModule,
).pipe(Layer.provideMerge(DbLive));

const july = { name: "July", startDate: "2026-07-01", endDate: "2026-07-31" };

const category = Effect.fn("category")(function* (name: string) {
  const categories = yield* CategoriesService;
  return (yield* categories.create({ name, color: "#112233", icon: null })).id;
});

const newPeriod = Effect.fn("newPeriod")(function* (
  currency?: "PLN" | "EUR" | "JPY",
  categoryId?: CategoryId,
) {
  const budgets = yield* BudgetsService;
  return yield* budgets.createPeriod({
    ...july,
    incomeMinor: 100_000,
    ...(currency === undefined ? {} : { currency }),
    envelopes:
      categoryId === undefined ? [] : [{ categoryId, plannedMinor: 10_000 }],
  });
});

layer(TestLayer)("currency", (it) => {
  it.effect(
    "a period defaults to PLN and can be created in another currency",
    () =>
      Effect.gen(function* () {
        yield* resetDb;
        const budgets = yield* BudgetsService;
        assert.strictEqual((yield* newPeriod()).period.currency, "PLN");
        const eur = yield* newPeriod("EUR");
        assert.strictEqual(eur.period.currency, "EUR");
        assert.strictEqual(
          (yield* budgets.getPeriod(eur.period.id)).period.currency,
          "EUR",
        );
      }).pipe(Effect.provide(TestLayer)),
  );

  it.effect(
    "an expense paid in another currency keeps what was actually paid",
    () =>
      Effect.gen(function* () {
        yield* resetDb;
        const expenses = yield* ExpensesService;
        const food = yield* category("Food");
        const period = yield* newPeriod("PLN", food);
        const envelopeId = period.envelopes[0]!.id;
        const base = {
          envelopeId,
          amountMinor: 2_000,
          spentAt: DateTime.makeUnsafe("2026-07-03T10:00:00Z"),
          note: null,
        };

        const plain = yield* expenses.create(base);
        assert.isNull(plain.originalAmountMinor);
        assert.isNull(plain.originalCurrency);

        const dollars = yield* expenses.create({
          ...base,
          original: { amountMinor: 500, currency: "USD" },
        });
        assert.strictEqual(dollars.amountMinor, 2_000);
        assert.strictEqual(dollars.originalAmountMinor, 500);
        assert.strictEqual(dollars.originalCurrency, "USD");

        // "paid in the currency of the period" is an ordinary expense
        const same = yield* expenses.create({
          ...base,
          original: { amountMinor: 2_000, currency: "PLN" },
        });
        assert.isNull(same.originalCurrency);

        // editing can set and clear it
        const cleared = yield* expenses.update(dollars.id, {
          envelopeId,
          amountMinor: 2_000,
          spentAt: base.spentAt,
          note: null,
        });
        assert.isNull(cleared.originalCurrency);
        const set = yield* expenses.update(same.id, {
          envelopeId,
          amountMinor: 2_000,
          spentAt: base.spentAt,
          note: null,
          original: { amountMinor: 450, currency: "EUR" },
        });
        assert.strictEqual(set.originalCurrency, "EUR");

        // the envelope only counts the amount in the period's currency
        const progress = yield* expenses.progress(period.period.id);
        assert.strictEqual(progress.spentMinor, 6_000);
      }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("recurring rules apply only to periods in their currency", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const recurring = yield* RecurringService;
      const rent = yield* category("Rent");
      const pln = yield* newPeriod("PLN");
      yield* recurring.create({
        categoryId: rent,
        amountMinor: 200_000,
        frequency: "monthly",
        note: null,
        active: true,
      });
      yield* recurring.create({
        categoryId: rent,
        amountMinor: 50_000,
        currency: "EUR",
        frequency: "monthly",
        note: null,
        active: true,
      });

      assert.deepStrictEqual(
        (yield* recurring.suggestedPlan()).map((p) => p.plannedMinor),
        [200_000],
      );
      assert.deepStrictEqual(
        (yield* recurring.suggestedPlan("EUR")).map((p) => p.plannedMinor),
        [50_000],
      );
      assert.strictEqual(
        (yield* recurring.applyToPeriod(pln.period.id)).added,
        1,
      );
      const eur = yield* newPeriod("EUR");
      assert.strictEqual(
        (yield* recurring.applyToPeriod(eur.period.id)).added,
        1,
      );
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("CSV carries the currency and respects its decimal places", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const transfer = yield* TransferService;
      const budgets = yield* BudgetsService;
      const expenses = yield* ExpensesService;

      const csv = [
        "Period,Category,Amount,Date,Note,Currency",
        "Tokyo,Food,1500,2026-07-03,ramen,JPY",
        "Tokyo,Food,300,2026-07-04,,JPY",
        "Berlin,Food,12.50,2026-07-05,,EUR",
        "Home,Food,9.99,2026-07-06,,",
      ].join("\n");
      assert.deepStrictEqual(yield* transfer.importCsv(csv), {
        imported: 4,
        skipped: 0,
      });

      const periods = Object.fromEntries(
        (yield* budgets.listPeriods).map((p) => [p.name, p]),
      );
      assert.strictEqual(periods.Tokyo?.currency, "JPY");
      assert.strictEqual(periods.Berlin?.currency, "EUR");
      assert.strictEqual(periods.Home?.currency, "PLN");
      const tokyo = yield* expenses.listForPeriod(periods.Tokyo!.id, {});
      assert.deepStrictEqual(
        tokyo.map((e) => e.amountMinor),
        [300, 1_500],
      ); // no decimals in JPY
      const berlin = yield* expenses.listForPeriod(periods.Berlin!.id, {});
      assert.strictEqual(berlin[0]?.amountMinor, 1_250);

      // and it exports the same way, so it can be imported back unchanged
      const exported = yield* transfer.exportCsv;
      assert.include(exported, "Tokyo,Food,1500,2026-07-03,ramen,JPY");
      assert.include(exported, "Berlin,Food,12.50,2026-07-05,,EUR");
      assert.deepStrictEqual(yield* transfer.importCsv(exported), {
        imported: 0,
        skipped: 4,
      });
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("CSV rejects a currency that contradicts the period", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const transfer = yield* TransferService;
      const budgets = yield* BudgetsService;
      const csv = [
        "Period,Category,Amount,Date,Note,Currency",
        "Berlin,Food,1,2026-07-05,,EUR",
        "Berlin,Food,2,2026-07-06,,USD",
      ].join("\n");
      const error = yield* transfer.importCsv(csv).pipe(Effect.flip);
      assert.instanceOf(error, InvalidCsv);
      assert.strictEqual(error.line, 3);
      assert.deepStrictEqual(yield* budgets.listPeriods, []);

      const unsupported = yield* transfer
        .importCsv(
          "Period,Category,Amount,Date,Note,Currency\nB,F,1,2026-07-05,,XXX\n",
        )
        .pipe(Effect.flip);
      assert.instanceOf(unsupported, InvalidCsv);
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("a snapshot keeps currencies through export and import", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const transfer = yield* TransferService;
      const budgets = yield* BudgetsService;
      const expenses = yield* ExpensesService;
      const food = yield* category("Food");
      const period = yield* newPeriod("EUR", food);
      yield* expenses.create({
        envelopeId: period.envelopes[0]!.id,
        amountMinor: 2_000,
        spentAt: DateTime.makeUnsafe("2026-07-03T10:00:00Z"),
        note: null,
        original: { amountMinor: 500, currency: "USD" },
      });

      const snapshot = yield* transfer.export;
      yield* resetDb;
      yield* transfer.importDocument(snapshot);

      const restored = yield* budgets.getPeriod(period.period.id);
      assert.strictEqual(restored.period.currency, "EUR");
      const [expense] = yield* expenses.listForPeriod(period.period.id, {});
      assert.strictEqual(expense?.originalCurrency, "USD");
      assert.strictEqual(expense?.originalAmountMinor, 500);
    }).pipe(Effect.provide(TestLayer)),
  );
});

it("each currency has the decimal places of its minor unit", () => {
  assert.strictEqual(exponentOf("PLN"), 2);
  assert.strictEqual(exponentOf("JPY"), 0);
});
