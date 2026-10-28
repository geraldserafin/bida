import { IncomeNotFound } from "@bida/api-contract";
import { assert, layer } from "@effect/vitest";
import { Effect, Layer } from "effect";
import { DbLive } from "../../platform/db.ts";
import { insertUser, resetDb } from "../../platform/testing.ts";
import { IncomesModule, IncomesService } from "./incomes.module.ts";

const TestLayer = IncomesModule.pipe(Layer.provideMerge(DbLive));

layer(TestLayer)("IncomesService", (it) => {
  it.effect("income belongs to its user, newest first, within a range", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const incomes = yield* IncomesService;
      const ann = yield* insertUser();
      const bob = yield* insertUser();

      const salary = yield* incomes.create(ann.id, {
        amountMinor: 500_000,
        receivedOn: "2026-07-01",
        note: "salary",
      });
      yield* incomes.create(ann.id, {
        amountMinor: 20_000,
        receivedOn: "2026-08-03",
        note: null,
      });
      yield* incomes.create(bob.id, {
        amountMinor: 1,
        receivedOn: "2026-07-01",
        note: null,
      });

      assert.deepStrictEqual(
        (yield* incomes.list(ann.id, {})).map((i) => i.amountMinor),
        [20_000, 500_000],
      );
      assert.deepStrictEqual(
        (yield* incomes.list(ann.id, {
          from: "2026-07-01",
          to: "2026-07-31",
        })).map((i) => i.id),
        [salary.id],
      );
      assert.strictEqual((yield* incomes.list(bob.id, {})).length, 1);
    }),
  );

  it.effect("only the user changes or deletes their income", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const incomes = yield* IncomesService;
      const ann = yield* insertUser();
      const bob = yield* insertUser();
      const salary = yield* incomes.create(ann.id, {
        amountMinor: 100,
        receivedOn: "2026-07-01",
        note: null,
      });

      const updated = yield* incomes.update(ann.id, salary.id, {
        amountMinor: 200,
        receivedOn: "2026-07-02",
        note: "raise",
      });
      assert.strictEqual(updated.amountMinor, 200);
      assert.strictEqual(updated.receivedOn, "2026-07-02");

      const foreign = yield* incomes
        .update(bob.id, salary.id, {
          amountMinor: 1,
          receivedOn: "2026-07-02",
          note: null,
        })
        .pipe(Effect.flip);
      assert.instanceOf(foreign, IncomeNotFound);
      assert.instanceOf(
        yield* incomes.remove(bob.id, salary.id).pipe(Effect.flip),
        IncomeNotFound,
      );

      yield* incomes.remove(ann.id, salary.id);
      assert.deepStrictEqual(yield* incomes.list(ann.id, {}), []);
    }),
  );
});
