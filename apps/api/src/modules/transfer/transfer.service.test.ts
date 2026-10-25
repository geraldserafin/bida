import {
  type EnvelopeId,
  ExportDocument,
  InvalidCsv,
  InvalidImport,
  type LegacyBackup,
  type UserId,
} from "@bida/api-contract";
import { assert, layer } from "@effect/vitest";
import { DateTime, Effect, Layer, Schema } from "effect";
import { DbLive } from "../../platform/db.ts";
import { insertUser, resetDb } from "../../platform/testing.ts";
import {
  EnvelopesModule,
  EnvelopesService,
} from "../envelopes/envelopes.module.ts";
import {
  ExpensesModule,
  ExpensesService,
} from "../expenses/expenses.module.ts";
import { IncomesModule, IncomesService } from "../incomes/incomes.module.ts";
import {
  RecurringModule,
  RecurringService,
} from "../recurring/recurring.module.ts";
import { TransferModule, TransferService } from "./transfer.module.ts";

// Real services on the test database: ownership, foreign keys and the
// replacement of all data are the point of these tests.
const TestLayer = Layer.mergeAll(
  TransferModule,
  EnvelopesModule,
  IncomesModule,
  ExpensesModule,
  RecurringModule,
).pipe(Layer.provideMerge(DbLive));

const look = { color: "#112233", icon: null } as const;

/** Ann has Home (with Rent) and Food, income, money in them, expenses and a rule. */
const setup = Effect.gen(function* () {
  yield* resetDb;
  const envelopes = yield* EnvelopesService;
  const incomes = yield* IncomesService;
  const expenses = yield* ExpensesService;
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
  const food = yield* envelopes.create(ann.id, {
    parentId: null,
    name: "Food",
    ...look,
  });
  yield* incomes.create(ann.id, {
    amountMinor: 500_000,
    receivedOn: "2026-07-01",
    note: null,
  });
  for (const [envelopeId, amountMinor] of [
    [home.id, 100_000],
    [rent.id, 40_000],
    [food.id, 30_000],
  ] as const) {
    yield* envelopes.createAllocation(ann.id, {
      envelopeId,
      amountMinor,
      madeOn: "2026-07-01",
      note: null,
    });
  }
  const rule = yield* recurring.create(ann.id, {
    envelopeId: rent.id,
    amountMinor: 40_000,
    frequency: "monthly",
    note: "rent",
    active: true,
  });
  yield* recurring.apply(ann.id, { from: "2026-07-01", to: "2026-07-31" });
  yield* expenses.create(ann.id, {
    envelopeId: food.id,
    amountMinor: 4_599,
    spentAt: DateTime.makeUnsafe("2026-07-03T10:30:00Z"),
    note: "bread",
  });
  return { ann, bob, home, rent, food, rule };
});

const counts = {
  envelopes: 3,
  allocations: 3,
  incomes: 1,
  expenses: 2,
  recurringRules: 1,
};

/** The document as it would arrive over the wire. */
const roundTrip = (doc: ExportDocument) =>
  Schema.decodeUnknownSync(ExportDocument)(
    JSON.parse(JSON.stringify(Schema.encodeSync(ExportDocument)(doc))),
  );

layer(TestLayer)("TransferService", (it) => {
  it.effect("exports the data of the user and nobody else's", () =>
    Effect.gen(function* () {
      const { ann, bob } = yield* setup;
      const transfer = yield* TransferService;
      const mine = yield* transfer.export(ann.id);
      assert.strictEqual(mine.version, 2);
      assert.deepStrictEqual(
        {
          envelopes: mine.envelopes.length,
          allocations: mine.allocations.length,
          incomes: mine.incomes.length,
          expenses: mine.expenses.length,
          recurringRules: mine.recurringRules.length,
        },
        counts,
      );
      const empty = yield* transfer.export(bob.id);
      assert.strictEqual(empty.envelopes.length, 0);
      assert.strictEqual(empty.expenses.length, 0);
    }),
  );

  it.effect("a document loads as the data of whoever imports it", () =>
    Effect.gen(function* () {
      const { ann, bob } = yield* setup;
      const transfer = yield* TransferService;
      const envelopes = yield* EnvelopesService;
      const doc = roundTrip(yield* transfer.export(ann.id));

      assert.deepStrictEqual(
        yield* transfer.importDocument(bob.id, doc),
        counts,
      );

      const bobs = yield* transfer.export(bob.id);
      assert.deepStrictEqual(bobs.envelopes.map((e) => e.name).sort(), [
        "Food",
        "Home",
        "Rent",
      ]);
      assert.isTrue(bobs.envelopes.every((e) => e.ownerId === bob.id));
      assert.isTrue(bobs.allocations.every((a) => a.userId === bob.id));
      assert.isTrue(bobs.expenses.every((x) => x.createdBy === bob.id));
      // the structure survives, with new ids
      const home = bobs.envelopes.find((e) => e.name === "Home");
      assert.strictEqual(
        bobs.envelopes.find((e) => e.name === "Rent")?.parentId,
        home?.id,
      );
      const original = (yield* envelopes.list(ann.id)).map((e) => e.id);
      assert.isFalse(bobs.envelopes.some((e) => original.includes(e.id)));

      // Ann still has everything
      assert.strictEqual((yield* transfer.export(ann.id)).envelopes.length, 3);
    }),
  );

  it.effect("importing replaces what the user had, also their own backup", () =>
    Effect.gen(function* () {
      const { ann } = yield* setup;
      const transfer = yield* TransferService;
      const envelopes = yield* EnvelopesService;
      const doc = roundTrip(yield* transfer.export(ann.id));
      yield* envelopes.create(ann.id, {
        parentId: null,
        name: "Extra",
        ...look,
      });

      assert.deepStrictEqual(
        yield* transfer.importDocument(ann.id, doc),
        counts,
      );
      assert.deepStrictEqual(
        (yield* envelopes.list(ann.id)).map((e) => e.name),
        ["Food", "Home", "Rent"],
      );
      // loaded twice it is still one copy
      yield* transfer.importDocument(ann.id, doc);
      assert.strictEqual((yield* transfer.export(ann.id)).envelopes.length, 3);
    }),
  );

  it.effect("previews what an import would replace", () =>
    Effect.gen(function* () {
      const { ann, bob } = yield* setup;
      const transfer = yield* TransferService;
      const doc = roundTrip(yield* transfer.export(ann.id));
      const preview = yield* transfer.previewImport(bob.id, doc);
      assert.deepStrictEqual(preview.incoming, counts);
      assert.strictEqual(preview.current.envelopes, 0);
    }),
  );

  it.effect(
    "refuses a document that does not hold together and keeps the data",
    () =>
      Effect.gen(function* () {
        const { ann } = yield* setup;
        const transfer = yield* TransferService;
        const doc = roundTrip(yield* transfer.export(ann.id));
        const broken = {
          ...doc,
          expenses: doc.expenses.map((x) => ({
            ...x,
            envelopeId: "019845e1-682f-4b02-a706-3b2422d13aec" as EnvelopeId,
          })),
        };
        const error = yield* transfer
          .importDocument(ann.id, broken)
          .pipe(Effect.flip);
        assert.instanceOf(error, InvalidImport);
        assert.strictEqual(
          (yield* transfer.export(ann.id)).envelopes.length,
          3,
        );
      }),
  );

  it.effect(
    "exports expenses as CSV with the sub-envelope in its own column",
    () =>
      Effect.gen(function* () {
        const { ann } = yield* setup;
        const transfer = yield* TransferService;
        const lines = (yield* transfer.exportCsv(ann.id)).trim().split("\n");
        assert.strictEqual(lines[0], "Envelope,Subenvelope,Amount,Date,Note");
        // the rule was applied with the clock at the start, so it is dated the first of July
        assert.deepStrictEqual(lines.slice(1), [
          "Food,,45.99,2026-07-03,bread",
          "Home,Rent,400.00,2026-07-01,rent",
        ]);
      }),
  );

  it.effect(
    "imports CSV: creates envelopes by name and skips what is there",
    () =>
      Effect.gen(function* () {
        yield* resetDb;
        const transfer = yield* TransferService;
        const envelopes = yield* EnvelopesService;
        const expenses = yield* ExpensesService;
        const ann = yield* insertUser();
        const csv = [
          "Envelope,Subenvelope,Amount,Date,Note",
          "Home,Rent,400.00,2026-07-01,rent",
          "home,,12.5,2026-07-02,",
          "Food,,45.99,2026-07-03,bread",
          "Food,,45.99,2026-07-03,bread",
        ].join("\n");

        // the same row twice in one file is one expense
        assert.deepStrictEqual(yield* transfer.importCsv(ann.id, csv), {
          imported: 3,
          skipped: 1,
        });
        const names = (yield* envelopes.list(ann.id)).map((e) => e.name);
        assert.deepStrictEqual(names, ["Food", "Home", "Rent"]);
        assert.strictEqual((yield* expenses.list(ann.id, {})).length, 3);

        // loading it again adds nothing
        assert.deepStrictEqual(yield* transfer.importCsv(ann.id, csv), {
          imported: 0,
          skipped: 4,
        });
      }),
  );

  it.effect("imports nothing from a CSV with a bad row", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const transfer = yield* TransferService;
      const envelopes = yield* EnvelopesService;
      const ann = yield* insertUser();
      const error = yield* transfer
        .importCsv(
          ann.id,
          "Envelope,Subenvelope,Amount,Date,Note\nHome,,10,2026-07-01,\nHome,,x,2026-07-01,\n",
        )
        .pipe(Effect.flip);
      assert.instanceOf(error, InvalidCsv);
      assert.strictEqual(error.line, 3);
      assert.deepStrictEqual(yield* envelopes.list(ann.id), []);
    }),
  );

  it.effect("imports a backup of the offline app", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const transfer = yield* TransferService;
      const ann = yield* insertUser();
      const backup: LegacyBackup = {
        version: 1,
        data: {
          categories: [{ id: 1, name: "Food", color: "#22C55E", icon: null }],
          periods: [
            {
              id: 7,
              name: "July",
              start_date: "2026-07-01T00:00:00.000",
              end_date: "2026-07-31T00:00:00.000",
              income: 5000,
            },
          ],
          splits: [
            { id: 3, period_id: 7, category_id: 1, planned_amount: 1200 },
          ],
          recurring_rules: [],
          expenses: [
            {
              id: 5,
              split_id: 3,
              amount: 45.99,
              date: "2026-07-03T10:30:00.000",
              note: null,
              recurring_id: null,
            },
          ],
        },
      };
      assert.deepStrictEqual(yield* transfer.importLegacy(ann.id, { backup }), {
        envelopes: 1,
        allocations: 1,
        incomes: 1,
        expenses: 1,
        recurringRules: 0,
      });
      const doc = yield* transfer.export(ann.id as UserId);
      assert.strictEqual(doc.incomes[0]?.amountMinor, 500_000);
      assert.strictEqual(doc.allocations[0]?.amountMinor, 120_000);
    }),
  );
});
