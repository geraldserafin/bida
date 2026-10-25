import {
  ExportDocument,
  InvalidCsv,
  InvalidImport,
  type LegacyBackup,
} from "@bida/api-contract";
import { assert, layer } from "@effect/vitest";
import { DateTime, Effect, Layer, Schema } from "effect";
import { DbLive } from "../../platform/db.ts";
import { resetDb } from "../../platform/testing.ts";
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
  RecurringModule,
  RecurringService,
} from "../recurring/recurring.module.ts";
import { TransferModule, TransferService } from "./transfer.module.ts";

// Real services on the test database: restore and CSV import are about what
// ends up in the tables (ids, foreign keys, rollbacks).
const TestLayer = Layer.mergeAll(
  TransferModule,
  RecurringModule,
  ExpensesModule,
  BudgetsModule,
  CategoriesModule,
).pipe(Layer.provideMerge(DbLive));

const encode = Schema.encodeSync(ExportDocument);
/** The exported document as plain JSON, without the export time. */
const plain = (doc: ExportDocument) => {
  const { exportedAt: _, ...rest } = encode(doc);
  return rest;
};

/** A small but complete data set: every table has rows. */
const seed = Effect.gen(function* () {
  const categories = yield* CategoriesService;
  const budgets = yield* BudgetsService;
  const expenses = yield* ExpensesService;
  const recurring = yield* RecurringService;
  const food = yield* categories.create({
    name: "Food",
    color: "#22C55E",
    icon: "restaurant",
  });
  const rent = yield* categories.create({
    name: "Rent",
    color: "#EC4899",
    icon: null,
  });
  const period = yield* budgets.createPeriod({
    name: "July",
    startDate: "2026-07-01",
    endDate: "2026-07-31",
    incomeMinor: 500_000,
    envelopes: [
      { categoryId: food.id, plannedMinor: 50_000 },
      { categoryId: rent.id, plannedMinor: 200_000 },
    ],
  });
  const foodEnvelope = period.envelopes.find((e) => e.categoryId === food.id)!;
  yield* expenses.create({
    envelopeId: foodEnvelope.id,
    amountMinor: 4_599,
    spentAt: DateTime.makeUnsafe("2026-07-03T10:30:00Z"),
    note: 'Biedronka, "fresh"',
  });
  yield* recurring.create({
    categoryId: rent.id,
    amountMinor: 200_000,
    frequency: "monthly",
    note: "Rent",
    active: true,
  });
  yield* recurring.applyToPeriod(period.period.id);
  return { food, rent, period };
});

const legacy = (): LegacyBackup => ({
  version: 1,
  data: {
    categories: [{ id: 1, name: "Food", color: "#22C55E", icon: "restaurant" }],
    periods: [
      {
        id: 7,
        name: "July",
        start_date: "2026-07-01T00:00:00.000",
        end_date: "2026-07-31T00:00:00.000",
        income: 5000.5,
      },
    ],
    splits: [{ id: 3, period_id: 7, category_id: 1, planned_amount: 1200.25 }],
    recurring_rules: [
      {
        id: 9,
        category_id: 1,
        amount: 99.99,
        frequency: "monthly",
        note: "Gym",
        active: 1,
      },
    ],
    expenses: [
      {
        id: 5,
        split_id: 3,
        amount: 45.99,
        date: "2026-07-03T10:30:00.000",
        note: "Biedronka",
        recurring_id: 9,
      },
      {
        id: 6,
        split_id: 3,
        amount: 10,
        date: "2026-07-04T18:00:00.000",
        note: null,
        recurring_id: null,
      },
    ],
  },
});

layer(TestLayer)("TransferService", (it) => {
  it.effect("an export restores into an empty database identically", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const transfer = yield* TransferService;
      yield* seed;
      const before = yield* transfer.export;
      assert.deepStrictEqual(
        [
          before.categories.length,
          before.periods.length,
          before.envelopes.length,
          before.expenses.length,
          before.recurringRules.length,
        ],
        [2, 1, 2, 2, 1],
      );

      yield* resetDb;
      const counts = yield* transfer.importDocument(before);
      assert.deepStrictEqual(counts, {
        categories: 2,
        periods: 1,
        envelopes: 2,
        expenses: 2,
        recurringRules: 1,
      });
      assert.deepStrictEqual(plain(yield* transfer.export), plain(before));
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("an import replaces the current data", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const transfer = yield* TransferService;
      const categories = yield* CategoriesService;
      yield* seed;
      const snapshot = yield* transfer.export;

      // something that is not part of the snapshot
      yield* categories.create({ name: "Extra", color: "#112233", icon: null });
      const preview = yield* transfer.previewImport(snapshot);
      assert.strictEqual(preview.incoming.categories, 2);
      assert.strictEqual(preview.current.categories, 3);

      yield* transfer.importDocument(snapshot);
      assert.deepStrictEqual(
        (yield* categories.list).map((c) => c.name).sort(),
        ["Food", "Rent"],
      );
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("a broken document is refused and nothing changes", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const transfer = yield* TransferService;
      yield* seed;
      const snapshot = yield* transfer.export;
      const before = plain(snapshot);

      // an envelope whose period is not in the document
      const broken = { ...snapshot, periods: [] };
      const error = yield* transfer.importDocument(broken).pipe(Effect.flip);
      assert.instanceOf(error, InvalidImport);
      assert.deepStrictEqual(plain(yield* transfer.export), before);

      // a document that passes the checks but breaks a constraint rolls back
      const duplicated = {
        ...snapshot,
        categories: [...snapshot.categories, ...snapshot.categories],
      };
      const constraint = yield* transfer
        .importDocument(duplicated)
        .pipe(Effect.flip);
      assert.instanceOf(constraint, InvalidImport);
      assert.deepStrictEqual(plain(yield* transfer.export), before);
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("imports a backup of the offline app", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const transfer = yield* TransferService;
      const expenses = yield* ExpensesService;
      const budgets = yield* BudgetsService;

      const counts = yield* transfer.importLegacy({ backup: legacy() });
      assert.deepStrictEqual(counts, {
        categories: 1,
        periods: 1,
        envelopes: 1,
        expenses: 2,
        recurringRules: 1,
      });

      const [period] = yield* budgets.listPeriods;
      assert.strictEqual(period?.incomeMinor, 500_050);
      const detail = yield* budgets.getPeriod(period!.id);
      assert.strictEqual(detail.plannedMinor, 120_025);
      const listed = yield* expenses.listForPeriod(period!.id, {});
      assert.deepStrictEqual(
        listed.map((e) => e.amountMinor),
        [1_000, 4_599],
      );
      // 10:30 Warsaw time in July is 08:30 UTC
      assert.strictEqual(
        DateTime.formatIso(listed[1]!.spentAt),
        "2026-07-03T08:30:00.000Z",
      );
      assert.isNotNull(listed[1]?.recurringId);
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("refuses a legacy backup with dangling references", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const transfer = yield* TransferService;
      const backup = legacy();
      const bad = {
        ...backup,
        data: {
          ...backup.data,
          splits: [{ id: 3, period_id: 99, category_id: 1, planned_amount: 1 }],
        },
      };
      const error = yield* transfer
        .importLegacy({ backup: bad })
        .pipe(Effect.flip);
      assert.instanceOf(error, InvalidImport);
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("exports expenses as CSV", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const transfer = yield* TransferService;
      const budgets = yield* BudgetsService;
      const { food } = yield* seed;
      // pin a second expense on an earlier day so the order is visible
      const detail = yield* budgets.getPeriod(
        (yield* budgets.listPeriods)[0]!.id,
      );
      const expenses = yield* ExpensesService;
      yield* expenses.create({
        envelopeId: detail.envelopes.find((e) => e.categoryId === food.id)!.id,
        amountMinor: 100,
        spentAt: DateTime.makeUnsafe("2026-07-01T09:00:00Z"),
        note: null,
      });

      const csv = yield* transfer.exportCsv;
      const lines = csv.trimEnd().split("\n");
      assert.strictEqual(lines[0], "Period,Category,Amount,Date,Note");
      assert.strictEqual(lines.length, 4); // header + 3 expenses
      assert.include(csv, 'July,Food,45.99,2026-07-03,"Biedronka, ""fresh"""');
      assert.include(csv, "July,Food,1.00,2026-07-01,");
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("imports CSV, creating periods, categories and envelopes", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const transfer = yield* TransferService;
      const budgets = yield* BudgetsService;
      const categories = yield* CategoriesService;
      const expenses = yield* ExpensesService;

      const csv = [
        "Period,Category,Amount,Date,Note",
        "June 2026,Food,12.34,2026-06-03,lunch",
        'June 2026,food,5,2026-06-04,"a, b"',
        "June 2026,Fun,7.5,2026-06-05,",
      ].join("\n");
      const result = yield* transfer.importCsv(csv);
      assert.deepStrictEqual(result, { imported: 3, skipped: 0 });

      // "Food" and "food" are one category
      assert.deepStrictEqual(
        (yield* categories.list).map((c) => c.name).sort(),
        ["Food", "Fun"],
      );
      const [period] = yield* budgets.listPeriods;
      assert.strictEqual(period?.name, "June 2026");
      assert.strictEqual(period?.startDate, "2026-06-01");
      assert.strictEqual(period?.endDate, "2026-06-30");
      assert.strictEqual(period?.incomeMinor, 0);
      const detail = yield* budgets.getPeriod(period!.id);
      assert.strictEqual(detail.envelopes.length, 2);
      assert.strictEqual(detail.plannedMinor, 0);
      const listed = yield* expenses.listForPeriod(period!.id, {});
      assert.deepStrictEqual(
        listed.map((e) => e.amountMinor),
        [750, 500, 1234],
      );
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("importing the same CSV twice adds nothing the second time", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const transfer = yield* TransferService;
      const csv =
        "Period,Category,Amount,Date,Note\nJune,Food,12.34,2026-06-03,lunch\nJune,Food,12.34,2026-06-03,lunch\n";

      // the duplicate inside the file counts as skipped too
      assert.deepStrictEqual(yield* transfer.importCsv(csv), {
        imported: 1,
        skipped: 1,
      });
      assert.deepStrictEqual(yield* transfer.importCsv(csv), {
        imported: 0,
        skipped: 2,
      });
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("an exported CSV can be imported back", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const transfer = yield* TransferService;
      yield* seed;
      const csv = yield* transfer.exportCsv;
      const result = yield* transfer.importCsv(csv);
      assert.deepStrictEqual(result, { imported: 0, skipped: 2 });
    }).pipe(Effect.provide(TestLayer)),
  );

  it.effect("a bad CSV row refuses the whole file", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const transfer = yield* TransferService;
      const budgets = yield* BudgetsService;
      const csv =
        "Period,Category,Amount,Date,Note\nJune,Food,1,2026-06-03,ok\nJune,Food,nope,2026-06-03,bad\n";
      const error = yield* transfer.importCsv(csv).pipe(Effect.flip);
      assert.instanceOf(error, InvalidCsv);
      assert.strictEqual(error.line, 3);
      assert.deepStrictEqual(yield* budgets.listPeriods, []);
    }).pipe(Effect.provide(TestLayer)),
  );
});
