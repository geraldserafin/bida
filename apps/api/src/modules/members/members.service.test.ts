import {
  EnvelopeNotFound,
  Forbidden,
  LastOwner,
  LimitReached,
  MAX_MEMBERS_PER_ENVELOPE,
  MemberNotFound,
  NotEnoughMoney,
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
import {
  RecurringModule,
  RecurringService,
} from "../recurring/recurring.module.ts";
import { MembersModule, MembersService } from "./members.module.ts";

// Real services on the test database: access and the rules about whose money
// is whose are the point.
const TestLayer = Layer.mergeAll(
  MembersModule,
  EnvelopesModule,
  ExpensesModule,
  RecurringModule,
).pipe(Layer.provideMerge(DbLive));

const look = { color: "#112233", icon: null } as const;

/** Ann owns Home (with the sub-envelope Rent) and shares it with Bob as a member. */
const setup = Effect.gen(function* () {
  yield* resetDb;
  const envelopes = yield* EnvelopesService;
  const members = yield* MembersService;
  const ann = yield* insertUser();
  const bob = yield* insertUser();
  const cid = yield* insertUser();
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
  yield* members.add(home.id, bob.id, "member");
  return { envelopes, members, ann, bob, cid, home, rent };
});

const put = (
  envelopes: EnvelopesService["Service"],
  userId: Parameters<EnvelopesService["Service"]["list"]>[0],
  envelopeId: Parameters<EnvelopesService["Service"]["get"]>[1],
  amountMinor: number,
) =>
  envelopes.createAllocation(userId, {
    envelopeId,
    amountMinor,
    madeOn: "2026-07-01",
    note: null,
  });

layer(TestLayer)("MembersService", (it) => {
  it.effect(
    "members see the envelope and its sub-envelopes, others do not",
    () =>
      Effect.gen(function* () {
        const { envelopes, members, ann, bob, cid, home, rent } = yield* setup;

        assert.deepStrictEqual(
          (yield* envelopes.list(bob.id)).map((e) => e.name),
          ["Home", "Rent"],
        );
        assert.deepStrictEqual(
          (yield* members.list(bob.id, home.id)).map((m) => [m.email, m.role]),
          [
            [ann.email, "owner"],
            [bob.email, "member"],
          ],
        );
        // a sub-envelope has the members of its parent
        assert.strictEqual((yield* members.list(bob.id, rent.id)).length, 2);

        assert.deepStrictEqual(yield* envelopes.list(cid.id), []);
        assert.instanceOf(
          yield* members.list(cid.id, home.id).pipe(Effect.flip),
          EnvelopeNotFound,
        );
      }),
  );

  it.effect(
    "a member works with the money but does not manage the envelope",
    () =>
      Effect.gen(function* () {
        const { envelopes, members, ann, bob, home } = yield* setup;

        yield* put(envelopes, bob.id, home.id, 5_000);
        assert.instanceOf(
          yield* envelopes
            .update(bob.id, home.id, { name: "Mine", ...look })
            .pipe(Effect.flip),
          Forbidden,
        );
        assert.instanceOf(
          yield* envelopes.remove(bob.id, home.id).pipe(Effect.flip),
          Forbidden,
        );
        assert.instanceOf(
          yield* envelopes
            .create(bob.id, { parentId: home.id, name: "Extra", ...look })
            .pipe(Effect.flip),
          Forbidden,
        );
        assert.instanceOf(
          yield* members
            .setRole(bob.id, home.id, bob.id, "owner")
            .pipe(Effect.flip),
          Forbidden,
        );
        assert.instanceOf(
          yield* members.remove(bob.id, home.id, ann.id).pipe(Effect.flip),
          Forbidden,
        );
      }),
  );

  it.effect("everybody takes back only what they put in themselves", () =>
    Effect.gen(function* () {
      const { envelopes, ann, bob, home } = yield* setup;
      yield* put(envelopes, ann.id, home.id, 10_000);
      yield* put(envelopes, bob.id, home.id, 5_000);

      // 15 000 are in the envelope, but only 5 000 are Bob's
      const tooMuch = yield* put(envelopes, bob.id, home.id, -6_000).pipe(
        Effect.flip,
      );
      assert.instanceOf(tooMuch, NotEnoughMoney);
      assert.strictEqual(tooMuch.availableMinor, 5_000);
      yield* put(envelopes, bob.id, home.id, -5_000);
    }),
  );

  it.effect(
    "shows who put how much into the envelope and each sub-envelope",
    () =>
      Effect.gen(function* () {
        const { envelopes, members, ann, bob, home, rent } = yield* setup;
        yield* put(envelopes, ann.id, home.id, 10_000);
        yield* put(envelopes, bob.id, home.id, 5_000);
        yield* put(envelopes, ann.id, rent.id, 3_000);
        yield* put(envelopes, bob.id, rent.id, 2_000);
        yield* put(envelopes, bob.id, home.id, -500);

        const all = yield* members.contributions(bob.id, home.id);
        const of = (envelopeId: string, userId: string) =>
          all.find((c) => c.envelopeId === envelopeId && c.userId === userId)
            ?.amountMinor;
        assert.deepStrictEqual(
          [
            of(home.id, ann.id),
            of(home.id, bob.id),
            of(rent.id, ann.id),
            of(rent.id, bob.id),
          ],
          [10_000, 4_500, 3_000, 2_000],
        );

        // asked about the sub-envelope, only its own
        const sub = yield* members.contributions(ann.id, rent.id);
        assert.deepStrictEqual(
          sub.map((c) => c.envelopeId),
          [rent.id, rent.id],
        );
      }),
  );

  it.effect(
    "expenses of others are visible; the author and an owner change them",
    () =>
      Effect.gen(function* () {
        const { ann, bob, home } = yield* setup;
        const expenses = yield* ExpensesService;
        const input = (amountMinor: number) => ({
          envelopeId: home.id,
          amountMinor,
          spentAt: DateTime.makeUnsafe("2026-07-03T10:00:00Z"),
          note: null,
        });
        const byAnn = yield* expenses.create(ann.id, input(100));
        const byBob = yield* expenses.create(bob.id, input(200));

        assert.strictEqual((yield* expenses.list(bob.id, {})).length, 2);
        assert.instanceOf(
          yield* expenses.remove(bob.id, byAnn.id).pipe(Effect.flip),
          Forbidden,
        );
        yield* expenses.remove(ann.id, byBob.id); // an owner may
        yield* expenses.remove(
          bob.id,
          (yield* expenses.create(bob.id, input(1))).id,
        );
      }),
  );

  it.effect("an owner makes somebody an owner, and the last owner stays", () =>
    Effect.gen(function* () {
      const { members, ann, bob, home } = yield* setup;

      assert.instanceOf(
        yield* members
          .setRole(ann.id, home.id, ann.id, "member")
          .pipe(Effect.flip),
        LastOwner,
      );
      assert.instanceOf(
        yield* members.remove(ann.id, home.id, ann.id).pipe(Effect.flip),
        LastOwner,
      );

      const promoted = yield* members.setRole(ann.id, home.id, bob.id, "owner");
      assert.strictEqual(promoted.role, "owner");
      // now Ann may step down and leave
      yield* members.setRole(bob.id, home.id, ann.id, "member");
      yield* members.remove(ann.id, home.id, ann.id);
      assert.deepStrictEqual(
        (yield* members.list(bob.id, home.id)).map((m) => m.userId),
        [bob.id],
      );
    }),
  );

  it.effect(
    "somebody who leaves loses access but leaves their money and expenses",
    () =>
      Effect.gen(function* () {
        const { envelopes, members, ann, bob, home } = yield* setup;
        const expenses = yield* ExpensesService;
        const recurring = yield* RecurringService;
        yield* put(envelopes, bob.id, home.id, 5_000);
        yield* expenses.create(bob.id, {
          envelopeId: home.id,
          amountMinor: 100,
          spentAt: DateTime.makeUnsafe("2026-07-03T10:00:00Z"),
          note: null,
        });
        yield* recurring.create(bob.id, {
          envelopeId: home.id,
          amountMinor: 100,
          frequency: "monthly",
          note: null,
          active: true,
        });

        yield* members.remove(bob.id, home.id, bob.id);

        assert.deepStrictEqual(yield* envelopes.list(bob.id), []);
        assert.deepStrictEqual(yield* recurring.list(bob.id), []);
        // the money and the expense stay in the envelope, where Ann sees them
        assert.strictEqual(
          (yield* members.contributions(ann.id, home.id))[0]?.amountMinor,
          5_000,
        );
        assert.strictEqual((yield* expenses.list(ann.id, {})).length, 1);
      }),
  );

  it.effect("an owner removes a member; a stranger is not a member", () =>
    Effect.gen(function* () {
      const { members, ann, bob, cid, home } = yield* setup;
      assert.instanceOf(
        yield* members.remove(ann.id, home.id, cid.id).pipe(Effect.flip),
        MemberNotFound,
      );
      yield* members.remove(ann.id, home.id, bob.id);
      assert.strictEqual((yield* members.list(ann.id, home.id)).length, 1);
    }),
  );

  it.effect("an envelope has a limit of members", () =>
    Effect.gen(function* () {
      const { members, home } = yield* setup;
      // Ann and Bob are in already
      for (let i = 2; i < MAX_MEMBERS_PER_ENVELOPE; i++) {
        const person = yield* insertUser();
        yield* members.add(home.id, person.id, "member");
      }
      const extra = yield* insertUser();
      const error = yield* members
        .add(home.id, extra.id, "member")
        .pipe(Effect.flip);
      assert.instanceOf(error, LimitReached);
      assert.strictEqual(error.limit, MAX_MEMBERS_PER_ENVELOPE);
    }),
  );

  it.effect("adding somebody who is in already changes nothing", () =>
    Effect.gen(function* () {
      const { members, bob, home } = yield* setup;
      const again = yield* members.add(home.id, bob.id, "owner");
      assert.strictEqual(again.role, "member");
    }),
  );
});
