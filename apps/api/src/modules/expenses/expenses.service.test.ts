import {
  EnvelopeNotFound,
  ExpenseNotFound,
  type UserId,
} from "@bida/api-contract";
import { assert, layer } from "@effect/vitest";
import { DateTime, Effect, Layer } from "effect";
import { DbLive } from "../../platform/db.ts";
import { insertUser, resetDb } from "../../platform/testing.ts";
import {
  EnvelopesModule,
  EnvelopesService,
} from "../envelopes/envelopes.module.ts";
import { ExpensesModule, ExpensesService } from "./expenses.module.ts";

// Real services on the test database: foreign keys and visibility are the point.
const TestLayer = Layer.mergeAll(ExpensesModule, EnvelopesModule).pipe(
  Layer.provideMerge(DbLive),
);

const at = (iso: string) => DateTime.makeUnsafe(iso);
const look = { color: "#112233", icon: null } as const;

/** Ann owns Home (with the sub-envelope Rent) and Food; Bob owns nothing. */
const setup = Effect.gen(function* () {
  yield* resetDb;
  const envelopes = yield* EnvelopesService;
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
  return { ann, bob, home, rent, food };
});

const spend = (
  userId: UserId,
  envelopeId: Parameters<ExpensesService["Service"]["create"]>[1]["envelopeId"],
  amountMinor: number,
  spentAt = "2026-07-03T10:30:00Z",
) =>
  Effect.flatMap(ExpensesService, (expenses) =>
    expenses.create(userId, {
      envelopeId,
      amountMinor,
      spentAt: at(spentAt),
      note: null,
    }),
  );

layer(TestLayer)("ExpensesService", (it) => {
  it.effect("records who spent the money", () =>
    Effect.gen(function* () {
      const { ann, food } = yield* setup;
      const expense = yield* spend(ann.id, food.id, 4_599);
      assert.strictEqual(expense.createdBy, ann.id);
      assert.strictEqual(expense.envelopeId, food.id);
      assert.strictEqual(expense.amountMinor, 4_599);
    }),
  );

  it.effect("cannot spend from an envelope the user cannot see", () =>
    Effect.gen(function* () {
      const { bob, food } = yield* setup;
      const error = yield* spend(bob.id, food.id, 100).pipe(Effect.flip);
      assert.instanceOf(error, EnvelopeNotFound);
    }),
  );

  it.effect("other people's expenses do not exist for the user", () =>
    Effect.gen(function* () {
      const { ann, bob, food } = yield* setup;
      const expenses = yield* ExpensesService;
      const expense = yield* spend(ann.id, food.id, 100);

      assert.instanceOf(
        yield* expenses.get(bob.id, expense.id).pipe(Effect.flip),
        ExpenseNotFound,
      );
      assert.instanceOf(
        yield* expenses.remove(bob.id, expense.id).pipe(Effect.flip),
        ExpenseNotFound,
      );
      assert.deepStrictEqual(yield* expenses.list(bob.id, {}), []);
    }),
  );

  it.effect("lists newest first, with sub-envelopes in their parent", () =>
    Effect.gen(function* () {
      const { ann, home, rent, food } = yield* setup;
      const expenses = yield* ExpensesService;
      yield* spend(ann.id, home.id, 1, "2026-07-01T10:00:00Z");
      yield* spend(ann.id, rent.id, 2, "2026-07-02T10:00:00Z");
      yield* spend(ann.id, food.id, 3, "2026-07-03T10:00:00Z");

      assert.deepStrictEqual(
        (yield* expenses.list(ann.id, {})).map((e) => e.amountMinor),
        [3, 2, 1],
      );
      assert.deepStrictEqual(
        (yield* expenses.list(ann.id, { envelopeId: home.id })).map(
          (e) => e.amountMinor,
        ),
        [2, 1],
      );
      assert.deepStrictEqual(
        (yield* expenses.list(ann.id, { envelopeId: rent.id })).map(
          (e) => e.amountMinor,
        ),
        [2],
      );
      assert.deepStrictEqual(
        (yield* expenses.list(ann.id, {
          from: at("2026-07-02T00:00:00Z"),
          to: at("2026-07-03T00:00:00Z"),
        })).map((e) => e.amountMinor),
        [2],
      );
      assert.strictEqual(
        (yield* expenses.list(ann.id, { limit: 1, offset: 1 }))[0]?.amountMinor,
        2,
      );
    }),
  );

  it.effect("an expense moves to another envelope the user can see", () =>
    Effect.gen(function* () {
      const { ann, bob, home, food } = yield* setup;
      const expenses = yield* ExpensesService;
      const envelopes = yield* EnvelopesService;
      const bobs = yield* envelopes.create(bob.id, {
        parentId: null,
        name: "Bob's",
        ...look,
      });
      const expense = yield* spend(ann.id, food.id, 100);

      const moved = yield* expenses.update(ann.id, expense.id, {
        envelopeId: home.id,
        amountMinor: 250,
        spentAt: at("2026-07-04T10:00:00Z"),
        note: "moved",
      });
      assert.strictEqual(moved.envelopeId, home.id);
      assert.strictEqual(moved.amountMinor, 250);

      const foreign = yield* expenses
        .update(ann.id, expense.id, {
          envelopeId: bobs.id,
          amountMinor: 1,
          spentAt: at("2026-07-04T10:00:00Z"),
          note: null,
        })
        .pipe(Effect.flip);
      assert.instanceOf(foreign, EnvelopeNotFound);
    }),
  );

  it.effect("deleting an envelope deletes its expenses", () =>
    Effect.gen(function* () {
      const { ann, home, rent } = yield* setup;
      const expenses = yield* ExpensesService;
      const envelopes = yield* EnvelopesService;
      const expense = yield* spend(ann.id, rent.id, 100);
      yield* envelopes.remove(ann.id, home.id);
      assert.instanceOf(
        yield* expenses.get(ann.id, expense.id).pipe(Effect.flip),
        ExpenseNotFound,
      );
    }),
  );
});
