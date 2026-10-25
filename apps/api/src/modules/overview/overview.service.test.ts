import {
  type EnvelopeFigures,
  InvalidRange,
  InvalidTimeZone,
} from "@bida/api-contract";
import { assert, layer } from "@effect/vitest";
import { DateTime, Effect, Layer } from "effect";
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
import { OverviewModule, OverviewService } from "./overview.module.ts";

// Real services on the test database: the sums are the point.
const TestLayer = Layer.mergeAll(
  OverviewModule,
  EnvelopesModule,
  ExpensesModule,
  IncomesModule,
).pipe(Layer.provideMerge(DbLive));

const look = { color: "#112233", icon: null } as const;

/**
 * Ann earns 1 000.00 in June and 2 000.00 in July. Home (with the
 * sub-envelope Rent) and Food get money and are spent from.
 */
const setup = Effect.gen(function* () {
  yield* resetDb;
  const envelopes = yield* EnvelopesService;
  const incomes = yield* IncomesService;
  const expenses = yield* ExpensesService;
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

  for (const [amountMinor, receivedOn] of [
    [100_000, "2026-06-15"],
    [200_000, "2026-07-01"],
  ] as const) {
    yield* incomes.create(ann.id, { amountMinor, receivedOn, note: null });
  }
  for (const [envelopeId, amountMinor, madeOn] of [
    [home.id, 60_000, "2026-06-20"],
    [rent.id, 20_000, "2026-06-21"],
    [food.id, 30_000, "2026-07-02"],
    [home.id, 10_000, "2026-07-05"],
  ] as const) {
    yield* envelopes.createAllocation(ann.id, {
      envelopeId,
      amountMinor,
      madeOn,
      note: null,
    });
  }
  for (const [envelopeId, amountMinor, spentAt] of [
    [rent.id, 5_000, "2026-06-25T10:00:00Z"],
    [home.id, 3_000, "2026-07-10T10:00:00Z"],
    [rent.id, 4_000, "2026-07-12T10:00:00Z"],
    [food.id, 10_000, "2026-07-15T10:00:00Z"],
  ] as const) {
    yield* expenses.create(ann.id, {
      envelopeId,
      amountMinor,
      spentAt: DateTime.makeUnsafe(spentAt),
      note: null,
    });
  }
  return { ann, bob, home, rent, food };
});

const July = { from: "2026-07-01", to: "2026-07-31" };

const figuresOf = (
  figures: ReadonlyArray<EnvelopeFigures>,
  id: string,
): EnvelopeFigures => {
  const found = figures.find((f) => f.envelopeId === id);
  if (found === undefined) throw new Error(`no figures for ${id}`);
  return found;
};

layer(TestLayer)("OverviewService", (it) => {
  it.effect(
    "adds up a month and rolls the balances over from the one before",
    () =>
      Effect.gen(function* () {
        const { ann, home, rent, food } = yield* setup;
        const overview = yield* OverviewService;
        const july = yield* overview.get(ann.id, July);

        assert.strictEqual(july.incomeMinor, 200_000);
        // only top-level envelopes take from the pool: 30 000 + 10 000
        assert.strictEqual(july.allocatedMinor, 40_000);
        assert.strictEqual(july.spentMinor, 17_000);
        // 300 000 earned, 100 000 put into top-level envelopes so far
        assert.strictEqual(july.poolMinor, 200_000);

        // Home includes Rent: 60 000 before minus 5 000 spent from Rent
        const h = figuresOf(july.envelopes, home.id);
        assert.strictEqual(h.openingMinor, 55_000);
        assert.strictEqual(h.allocatedMinor, 10_000);
        assert.strictEqual(h.spentMinor, 7_000);
        assert.strictEqual(h.balanceMinor, 58_000);

        const r = figuresOf(july.envelopes, rent.id);
        assert.strictEqual(r.parentId, home.id);
        assert.strictEqual(r.openingMinor, 15_000);
        assert.strictEqual(r.allocatedMinor, 0);
        assert.strictEqual(r.spentMinor, 4_000);
        assert.strictEqual(r.balanceMinor, 11_000);
        assert.strictEqual(r.freeMinor, 11_000);

        // what is in Home but not assigned to Rent
        assert.strictEqual(h.freeMinor, 47_000);

        const f = figuresOf(july.envelopes, food.id);
        assert.deepStrictEqual(
          [f.openingMinor, f.allocatedMinor, f.spentMinor, f.balanceMinor],
          [0, 30_000, 10_000, 20_000],
        );
      }),
  );

  it.effect("a month before the money is empty, the pool already counts", () =>
    Effect.gen(function* () {
      const { ann } = yield* setup;
      const overview = yield* OverviewService;
      const may = yield* overview.get(ann.id, {
        from: "2026-05-01",
        to: "2026-05-31",
      });
      assert.strictEqual(may.incomeMinor, 0);
      assert.strictEqual(may.poolMinor, 0);
      assert.isTrue(
        may.envelopes.every(
          (f) => f.balanceMinor === 0 && f.openingMinor === 0,
        ),
      );
    }),
  );

  it.effect("an expense falls on the day it has in the time zone", () =>
    Effect.gen(function* () {
      const { ann, food } = yield* setup;
      const expenses = yield* ExpensesService;
      const overview = yield* OverviewService;
      // 00:30 on 1 July in Warsaw, still 30 June in UTC
      yield* expenses.create(ann.id, {
        envelopeId: food.id,
        amountMinor: 700,
        spentAt: DateTime.makeUnsafe("2026-06-30T22:30:00Z"),
        note: null,
      });
      const warsaw = yield* overview.get(ann.id, July);
      const utc = yield* overview.get(ann.id, { ...July, timeZone: "UTC" });
      assert.strictEqual(warsaw.spentMinor, 17_700);
      assert.strictEqual(utc.spentMinor, 17_000);
    }),
  );

  it.effect("other people's money is not in it", () =>
    Effect.gen(function* () {
      const { bob } = yield* setup;
      const overview = yield* OverviewService;
      const july = yield* overview.get(bob.id, July);
      assert.strictEqual(july.incomeMinor, 0);
      assert.strictEqual(july.poolMinor, 0);
      assert.deepStrictEqual(july.envelopes, []);
    }),
  );

  it.effect("refuses a nonsense range or time zone", () =>
    Effect.gen(function* () {
      const { ann } = yield* setup;
      const overview = yield* OverviewService;
      assert.instanceOf(
        yield* overview
          .get(ann.id, { from: "2026-08-01", to: "2026-07-01" })
          .pipe(Effect.flip),
        InvalidRange,
      );
      assert.instanceOf(
        yield* overview
          .get(ann.id, { ...July, timeZone: "Mars/Phobos" })
          .pipe(Effect.flip),
        InvalidTimeZone,
      );
      assert.instanceOf(
        yield* overview
          .months(ann.id, { timeZone: "Mars/Phobos" })
          .pipe(Effect.flip),
        InvalidTimeZone,
      );
    }),
  );

  it.effect("the history lists every month, with the quiet ones empty", () =>
    Effect.gen(function* () {
      const { ann } = yield* setup;
      const overview = yield* OverviewService;
      const months = yield* overview.months(ann.id, { today: "2026-08-15" });
      const byStart = new Map(months.map((m) => [m.from, m]));

      const june = byStart.get("2026-06-01");
      assert.deepStrictEqual(
        [june?.to, june?.incomeMinor, june?.allocatedMinor, june?.spentMinor],
        ["2026-06-30", 100_000, 60_000, 5_000],
      );
      const july = byStart.get("2026-07-01");
      assert.deepStrictEqual(
        [july?.incomeMinor, july?.allocatedMinor, july?.spentMinor],
        [200_000, 40_000, 17_000],
      );
      // newest first, no gaps up to now
      const starts = months.map((m) => m.from);
      assert.deepStrictEqual(starts, [...starts].sort().reverse());
      assert.strictEqual(starts[0], "2026-08-01");
      assert.strictEqual(byStart.get("2026-08-01")?.spentMinor, 0);
    }),
  );

  it.effect("a budget month can start on another day", () =>
    Effect.gen(function* () {
      const { ann } = yield* setup;
      const overview = yield* OverviewService;
      const months = yield* overview.months(ann.id, {
        startDay: 10,
        today: "2026-08-15",
      });
      const byStart = new Map(months.map((m) => [m.from, m]));
      // the month that starts on 10 June lasts until 9 July, so it has both
      // incomes, the allocations up to 5 July (Rent is a sub-envelope and does
      // not count) and the 25 June expense
      const june = byStart.get("2026-06-10");
      assert.deepStrictEqual(
        [june?.to, june?.incomeMinor, june?.allocatedMinor, june?.spentMinor],
        ["2026-07-09", 300_000, 100_000, 5_000],
      );
    }),
  );
});
