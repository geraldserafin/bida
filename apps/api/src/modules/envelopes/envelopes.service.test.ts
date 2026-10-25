import {
  type EnvelopeId,
  EnvelopeNotFound,
  Forbidden,
  NotEnoughMoney,
  ParentMustBeTopLevel,
  type UserId,
} from "@bida/api-contract";
import { assert, layer } from "@effect/vitest";
import { Effect, Layer } from "effect";
import { DbLive } from "../../platform/db.ts";
import { insertUser, resetDb } from "../../platform/testing.ts";
import { EnvelopesModule, EnvelopesService } from "./envelopes.module.ts";

// Real services on the test database: the rules about money are the point.
const TestLayer = EnvelopesModule.pipe(Layer.provideMerge(DbLive));

const look = { color: "#112233", icon: null } as const;

/** Two people, and a top-level envelope "Home" with a sub-envelope "Rent". */
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
  return { envelopes, ann, bob, home, rent };
});

const put = (
  envelopes: EnvelopesService["Service"],
  userId: UserId,
  envelopeId: EnvelopeId,
  amountMinor: number,
  madeOn = "2026-07-01",
) =>
  envelopes.createAllocation(userId, {
    envelopeId,
    amountMinor,
    madeOn,
    note: null,
  });

layer(TestLayer)("EnvelopesService", (it) => {
  it.effect("an envelope belongs to its owner and nobody else sees it", () =>
    Effect.gen(function* () {
      const { envelopes, ann, bob, home, rent } = yield* setup;

      assert.deepStrictEqual(
        (yield* envelopes.list(ann.id)).map((e) => e.name),
        ["Home", "Rent"],
      );
      assert.strictEqual(home.ownerId, ann.id);
      assert.strictEqual(rent.parentId, home.id);

      assert.deepStrictEqual(yield* envelopes.list(bob.id), []);
      for (const id of [home.id, rent.id]) {
        const error = yield* envelopes.get(bob.id, id).pipe(Effect.flip);
        assert.instanceOf(error, EnvelopeNotFound);
      }
    }),
  );

  it.effect("sub-envelopes go one level deep and under a visible parent", () =>
    Effect.gen(function* () {
      const { envelopes, ann, bob, home, rent } = yield* setup;

      const deeper = yield* envelopes
        .create(ann.id, { parentId: rent.id, name: "Water", ...look })
        .pipe(Effect.flip);
      assert.instanceOf(deeper, ParentMustBeTopLevel);

      const foreign = yield* envelopes
        .create(bob.id, { parentId: home.id, name: "Mine now", ...look })
        .pipe(Effect.flip);
      assert.instanceOf(foreign, EnvelopeNotFound);
    }),
  );

  it.effect(
    "only the owner edits and deletes; deleting takes the children",
    () =>
      Effect.gen(function* () {
        const { envelopes, ann, home, rent } = yield* setup;

        const renamed = yield* envelopes.update(ann.id, home.id, {
          name: "House",
          ...look,
        });
        assert.strictEqual(renamed.name, "House");

        yield* envelopes.remove(ann.id, home.id);
        assert.deepStrictEqual(yield* envelopes.list(ann.id), []);
        const gone = yield* envelopes.get(ann.id, rent.id).pipe(Effect.flip);
        assert.instanceOf(gone, EnvelopeNotFound);
      }),
  );

  it.effect(
    "money goes into an envelope and is split between sub-envelopes",
    () =>
      Effect.gen(function* () {
        const { envelopes, ann, home, rent } = yield* setup;

        // the pool may go below zero, so putting money in never fails
        yield* put(envelopes, ann.id, home.id, 100_000);
        yield* put(envelopes, ann.id, rent.id, 50_000);

        // 100 000 put in, 50 000 assigned: 50 000 left to assign
        const tooMuch = yield* put(envelopes, ann.id, rent.id, 50_001).pipe(
          Effect.flip,
        );
        assert.instanceOf(tooMuch, NotEnoughMoney);
        assert.strictEqual(tooMuch.envelopeId, home.id);
        assert.strictEqual(tooMuch.availableMinor, 50_000);
        yield* put(envelopes, ann.id, rent.id, 50_000);

        const listed = yield* envelopes.listAllocations(ann.id, {
          envelopeId: home.id,
        });
        assert.deepStrictEqual(
          listed.map((a) => a.amountMinor).sort((a, b) => a - b),
          [50_000, 50_000, 100_000],
        );
      }),
  );

  it.effect(
    "what is assigned to a sub-envelope cannot be taken from the parent",
    () =>
      Effect.gen(function* () {
        const { envelopes, ann, home, rent } = yield* setup;
        const funding = yield* put(envelopes, ann.id, home.id, 100_000);
        yield* put(envelopes, ann.id, rent.id, 60_000);

        // 40 000 are not assigned yet
        const take = yield* put(envelopes, ann.id, home.id, -40_001).pipe(
          Effect.flip,
        );
        assert.instanceOf(take, NotEnoughMoney);
        assert.strictEqual(take.availableMinor, 40_000);
        yield* put(envelopes, ann.id, home.id, -40_000);

        // and the original funding cannot go either, nor be made smaller
        const remove = yield* envelopes
          .removeAllocation(ann.id, funding.id)
          .pipe(Effect.flip);
        assert.instanceOf(remove, NotEnoughMoney);
        const shrink = yield* envelopes
          .updateAllocation(ann.id, funding.id, {
            amountMinor: 50_000,
            madeOn: "2026-07-01",
            note: null,
          })
          .pipe(Effect.flip);
        assert.instanceOf(shrink, NotEnoughMoney);
      }),
  );

  it.effect("money comes back from a sub-envelope only up to what it has", () =>
    Effect.gen(function* () {
      const { envelopes, ann, home, rent } = yield* setup;
      yield* put(envelopes, ann.id, home.id, 100_000);
      yield* put(envelopes, ann.id, rent.id, 30_000);

      const tooMuch = yield* put(envelopes, ann.id, rent.id, -30_001).pipe(
        Effect.flip,
      );
      assert.instanceOf(tooMuch, NotEnoughMoney);
      assert.strictEqual(tooMuch.envelopeId, rent.id);
      yield* put(envelopes, ann.id, rent.id, -30_000);
    }),
  );

  it.effect("only the author changes an allocation", () =>
    Effect.gen(function* () {
      const { envelopes, ann, bob, home } = yield* setup;
      const funding = yield* put(envelopes, ann.id, home.id, 1_000);
      const error = yield* envelopes
        .removeAllocation(bob.id, funding.id)
        .pipe(Effect.flip);
      assert.strictEqual(error._tag, "AllocationNotFound");
    }),
  );

  it.effect("an envelope nobody can see takes no money and no structure", () =>
    Effect.gen(function* () {
      const { envelopes, bob, home } = yield* setup;
      const error = yield* put(envelopes, bob.id, home.id, 1_000).pipe(
        Effect.flip,
      );
      assert.instanceOf(error, EnvelopeNotFound);
      const forbidden = yield* envelopes
        .remove(bob.id, home.id)
        .pipe(Effect.flip);
      assert.instanceOf(forbidden, EnvelopeNotFound);
      assert.notInstanceOf(forbidden, Forbidden);
    }),
  );

  it.effect("the scope of an envelope is itself and its children", () =>
    Effect.gen(function* () {
      const { envelopes, ann, home, rent } = yield* setup;
      assert.deepStrictEqual(
        [...(yield* envelopes.scope(ann.id, home.id))].sort(),
        [home.id, rent.id].sort(),
      );
      assert.deepStrictEqual(yield* envelopes.scope(ann.id, rent.id), [
        rent.id,
      ]);
      assert.strictEqual((yield* envelopes.scope(ann.id, undefined)).length, 2);
    }),
  );
});
