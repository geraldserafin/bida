import { EnvelopeNotFound, RecurringRuleNotFound } from "@bida/api-contract";
import { assert, layer } from "@effect/vitest";
import { Effect, Layer } from "effect";
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
import { RecurringModule, RecurringService } from "./recurring.module.ts";

const TestLayer = Layer.mergeAll(
  RecurringModule,
  ExpensesModule,
  EnvelopesModule,
).pipe(Layer.provideMerge(DbLive));

const setup = Effect.gen(function* () {
  yield* resetDb;
  const envelopes = yield* EnvelopesService;
  const ann = yield* insertUser();
  const bob = yield* insertUser();
  const home = yield* envelopes.create(ann.id, {
    parentId: null,
    name: "Home",
    color: "#112233",
    icon: null,
  });
  return { ann, bob, home };
});

const July = { from: "2026-07-01", to: "2026-07-31" };

layer(TestLayer)("RecurringService", (it) => {
  it.effect("rules belong to their user and need a visible envelope", () =>
    Effect.gen(function* () {
      const { ann, bob, home } = yield* setup;
      const recurring = yield* RecurringService;
      const input = {
        envelopeId: home.id,
        amountMinor: 200_000,
        frequency: "monthly",
        note: "rent",
        active: true,
      } as const;

      const rule = yield* recurring.create(ann.id, input);
      assert.strictEqual(rule.userId, ann.id);
      assert.deepStrictEqual((yield* recurring.list(bob.id)).length, 0);

      assert.instanceOf(
        yield* recurring.create(bob.id, input).pipe(Effect.flip),
        EnvelopeNotFound,
      );
      assert.instanceOf(
        yield* recurring.remove(bob.id, rule.id).pipe(Effect.flip),
        RecurringRuleNotFound,
      );
      yield* recurring.remove(ann.id, rule.id);
      assert.deepStrictEqual(yield* recurring.list(ann.id), []);
    }),
  );

  it.effect("applying adds one expense per active rule and is repeatable", () =>
    Effect.gen(function* () {
      const { ann, home } = yield* setup;
      const recurring = yield* RecurringService;
      const expenses = yield* ExpensesService;
      yield* recurring.create(ann.id, {
        envelopeId: home.id,
        amountMinor: 200_000,
        frequency: "monthly",
        note: "rent",
        active: true,
      });
      yield* recurring.create(ann.id, {
        envelopeId: home.id,
        amountMinor: 5_000,
        frequency: "monthly",
        note: null,
        active: false,
      });

      assert.strictEqual((yield* recurring.apply(ann.id, July)).expenses, 1);
      assert.strictEqual((yield* recurring.apply(ann.id, July)).expenses, 0);
      const spent = yield* expenses.list(ann.id, {});
      assert.deepStrictEqual(
        spent.map((e) => e.amountMinor),
        [200_000],
      );
      assert.isNotNull(spent[0]?.recurringId);

      // another stretch gets its own expense
      assert.strictEqual(
        (yield* recurring.apply(ann.id, {
          from: "2026-08-01",
          to: "2026-08-31",
        })).expenses,
        1,
      );
    }),
  );

  it.effect("applying affects only the user's own rules", () =>
    Effect.gen(function* () {
      const { ann, bob, home } = yield* setup;
      const recurring = yield* RecurringService;
      yield* recurring.create(ann.id, {
        envelopeId: home.id,
        amountMinor: 100,
        frequency: "monthly",
        note: null,
        active: true,
      });
      assert.strictEqual((yield* recurring.apply(bob.id, July)).expenses, 0);
    }),
  );

  it.effect("deleting a rule keeps the expenses it made", () =>
    Effect.gen(function* () {
      const { ann, home } = yield* setup;
      const recurring = yield* RecurringService;
      const expenses = yield* ExpensesService;
      const rule = yield* recurring.create(ann.id, {
        envelopeId: home.id,
        amountMinor: 100,
        frequency: "monthly",
        note: null,
        active: true,
      });
      yield* recurring.apply(ann.id, July);
      yield* recurring.remove(ann.id, rule.id);
      const kept = yield* expenses.list(ann.id, {});
      assert.strictEqual(kept.length, 1);
      assert.isNull(kept[0]?.recurringId);
    }),
  );
});
