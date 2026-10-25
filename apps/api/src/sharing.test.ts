import {
  Forbidden,
  LastOwner,
  LimitReached,
  MAX_SPACES_PER_USER,
  MemberNotFound,
  PersonalSpace,
  SpaceNotEmpty,
  SpaceNotFound,
} from "@bida/api-contract";
import { assert, layer } from "@effect/vitest";
import { Effect, Layer } from "effect";
import { SpacesModule, SpacesService } from "./modules/spaces/spaces.module.ts";
import { DbLive } from "./platform/db.ts";
import { insertUser, resetDb } from "./platform/testing.ts";

const TestLayer = SpacesModule.pipe(Layer.provideMerge(DbLive));

/** A shared space and two other people, none of them in it yet. */
const setup = Effect.gen(function* () {
  yield* resetDb;
  const spaces = yield* SpacesService;
  const owner = yield* insertUser();
  const ann = yield* insertUser("ann@example.com");
  const bob = yield* insertUser("bob@example.com");
  const { space } = yield* spaces.createFor(owner.id, {
    name: "Home",
    defaultCurrency: "PLN",
  });
  return { spaces, owner, ann, bob, space };
});

layer(TestLayer)("shared spaces", (it) => {
  it.effect("a new space has its creator as the only owner", () =>
    Effect.gen(function* () {
      const { spaces, owner, space } = yield* setup;
      const members = yield* spaces.membersOf(owner.id, space.id);
      assert.deepStrictEqual(
        members.map((m) => [m.userId, m.role]),
        [[owner.id, "owner"]],
      );
      const mine = yield* spaces.listFor(owner.id);
      assert.strictEqual(mine[0]?.space.kind, "shared");
      assert.strictEqual(mine[0]?.memberCount, 1);
    }),
  );

  it.effect("members see the space and its members, outsiders do not", () =>
    Effect.gen(function* () {
      const { spaces, owner, ann, bob, space } = yield* setup;
      yield* spaces.addMember(space.id, ann.id, "member", 10);

      const seen = yield* spaces.membersOf(ann.id, space.id);
      assert.deepStrictEqual(
        seen.map((m) => [m.email, m.role]),
        [
          [(yield* spaces.membersOf(owner.id, space.id))[0]?.email, "owner"],
          ["ann@example.com", "member"],
        ],
      );
      assert.strictEqual((yield* spaces.listFor(ann.id))[0]?.memberCount, 2);
      assert.instanceOf(
        yield* spaces.membersOf(bob.id, space.id).pipe(Effect.flip),
        SpaceNotFound,
      );
    }),
  );

  it.effect("only owners edit the space, members and outsiders cannot", () =>
    Effect.gen(function* () {
      const { spaces, owner, ann, bob, space } = yield* setup;
      yield* spaces.addMember(space.id, ann.id, "member", 10);
      const input = { name: "Flat", defaultCurrency: "EUR" } as const;

      assert.strictEqual(
        (yield* spaces.updateFor(owner.id, space.id, input)).space.name,
        "Flat",
      );
      assert.instanceOf(
        yield* spaces.updateFor(ann.id, space.id, input).pipe(Effect.flip),
        Forbidden,
      );
      assert.instanceOf(
        yield* spaces.updateFor(bob.id, space.id, input).pipe(Effect.flip),
        SpaceNotFound,
      );
    }),
  );

  it.effect("owners change roles, but a space keeps an owner", () =>
    Effect.gen(function* () {
      const { spaces, owner, ann, space } = yield* setup;
      yield* spaces.addMember(space.id, ann.id, "member", 10);

      // the only owner cannot step down
      assert.instanceOf(
        yield* spaces
          .setRoleFor(owner.id, space.id, owner.id, "member")
          .pipe(Effect.flip),
        LastOwner,
      );
      // a member cannot change roles
      assert.instanceOf(
        yield* spaces
          .setRoleFor(ann.id, space.id, ann.id, "owner")
          .pipe(Effect.flip),
        Forbidden,
      );

      const promoted = yield* spaces.setRoleFor(
        owner.id,
        space.id,
        ann.id,
        "owner",
      );
      assert.strictEqual(promoted.role, "owner");
      // now there are two owners, so one can step down
      const stepped = yield* spaces.setRoleFor(
        owner.id,
        space.id,
        owner.id,
        "member",
      );
      assert.strictEqual(stepped.role, "member");
      assert.instanceOf(
        yield* spaces
          .setRoleFor(ann.id, space.id, ann.id, "member")
          .pipe(Effect.flip),
        LastOwner,
      );
    }),
  );

  it.effect(
    "two owners stepping down at the same time cannot empty the owners",
    () =>
      Effect.gen(function* () {
        const { spaces, owner, ann, space } = yield* setup;
        yield* spaces.addMember(space.id, ann.id, "owner", 10);

        const results = yield* Effect.all(
          [
            spaces.setRoleFor(owner.id, space.id, owner.id, "member"),
            spaces.setRoleFor(ann.id, space.id, ann.id, "member"),
          ],
          { concurrency: "unbounded", mode: "result" },
        );
        assert.strictEqual(
          results.filter((r) => r._tag === "Success").length,
          1,
        );
        const members = yield* spaces.membersOf(owner.id, space.id);
        assert.strictEqual(members.filter((m) => m.role === "owner").length, 1);
      }),
  );

  it.effect("owners remove members, who then lose the space", () =>
    Effect.gen(function* () {
      const { spaces, owner, ann, bob, space } = yield* setup;
      yield* spaces.addMember(space.id, ann.id, "member", 10);

      assert.instanceOf(
        yield* spaces
          .removeMemberFor(ann.id, space.id, owner.id)
          .pipe(Effect.flip),
        Forbidden,
      );
      assert.instanceOf(
        yield* spaces
          .removeMemberFor(owner.id, space.id, bob.id)
          .pipe(Effect.flip),
        MemberNotFound,
      );
      yield* spaces.removeMemberFor(owner.id, space.id, ann.id);
      assert.instanceOf(
        yield* spaces.membersOf(ann.id, space.id).pipe(Effect.flip),
        SpaceNotFound,
      );
      // the only owner cannot remove themselves either
      assert.instanceOf(
        yield* spaces
          .removeMemberFor(owner.id, space.id, owner.id)
          .pipe(Effect.flip),
        LastOwner,
      );
    }),
  );

  it.effect("members leave on their own, the last owner does not", () =>
    Effect.gen(function* () {
      const { spaces, owner, ann, space } = yield* setup;
      yield* spaces.addMember(space.id, ann.id, "member", 10);

      yield* spaces.leaveFor(ann.id, space.id);
      assert.deepStrictEqual(yield* spaces.listFor(ann.id), []);
      assert.instanceOf(
        yield* spaces.leaveFor(owner.id, space.id).pipe(Effect.flip),
        LastOwner,
      );
      // somebody who is not in the space has nothing to leave
      assert.instanceOf(
        yield* spaces.leaveFor(ann.id, space.id).pipe(Effect.flip),
        SpaceNotFound,
      );
    }),
  );

  it.effect(
    "a space is deleted only by its owner and only when alone in it",
    () =>
      Effect.gen(function* () {
        const { spaces, owner, ann, space } = yield* setup;
        yield* spaces.addMember(space.id, ann.id, "member", 10);

        assert.instanceOf(
          yield* spaces.deleteFor(ann.id, space.id).pipe(Effect.flip),
          Forbidden,
        );
        assert.instanceOf(
          yield* spaces.deleteFor(owner.id, space.id).pipe(Effect.flip),
          SpaceNotEmpty,
        );
        yield* spaces.removeMemberFor(owner.id, space.id, ann.id);
        yield* spaces.deleteFor(owner.id, space.id);
        assert.deepStrictEqual(yield* spaces.listFor(owner.id), []);
      }),
  );

  it.effect("a personal space cannot be shared, left, emptied or deleted", () =>
    Effect.gen(function* () {
      yield* resetDb;
      const spaces = yield* SpacesService;
      const me = yield* insertUser();
      const ann = yield* insertUser();
      const personal = yield* spaces.createPersonalFor(me.id, {
        name: "Mine",
        defaultCurrency: "PLN",
      });

      assert.strictEqual(
        (yield* spaces.listFor(me.id))[0]?.space.kind,
        "personal",
      );
      const refused = [
        yield* spaces.deleteFor(me.id, personal.id).pipe(Effect.flip),
        yield* spaces.leaveFor(me.id, personal.id).pipe(Effect.flip),
        yield* spaces
          .removeMemberFor(me.id, personal.id, me.id)
          .pipe(Effect.flip),
        yield* spaces
          .setRoleFor(me.id, personal.id, me.id, "member")
          .pipe(Effect.flip),
      ];
      for (const error of refused) assert.instanceOf(error, PersonalSpace);
      // nobody can be added through the members API either
      assert.instanceOf(
        yield* spaces.membersOf(ann.id, personal.id).pipe(Effect.flip),
        SpaceNotFound,
      );
    }),
  );

  it.effect("a user's personal space comes first in their list", () =>
    Effect.gen(function* () {
      const { spaces, owner } = yield* setup;
      yield* spaces.createPersonalFor(owner.id, {
        name: "Mine",
        defaultCurrency: "PLN",
      });
      const kinds = (yield* spaces.listFor(owner.id)).map((m) => m.space.kind);
      assert.deepStrictEqual(kinds, ["personal", "shared"]);
      // and it is what a request without a space header works in
      assert.strictEqual(
        (yield* spaces.resolveFor(owner.id, undefined)).space.kind,
        "personal",
      );
    }),
  );

  it.effect("limits the members of a space and the spaces of a user", () =>
    Effect.gen(function* () {
      const { spaces, owner, ann, bob, space } = yield* setup;

      yield* spaces.addMember(space.id, ann.id, "member", 2);
      assert.instanceOf(
        yield* spaces
          .addMember(space.id, bob.id, "member", 2)
          .pipe(Effect.flip),
        LimitReached,
      );

      for (let i = 1; i < MAX_SPACES_PER_USER; i++)
        yield* spaces.createFor(owner.id, {
          name: `S${i}`,
          defaultCurrency: "PLN",
        });
      assert.instanceOf(
        yield* spaces
          .createFor(owner.id, { name: "one too many", defaultCurrency: "PLN" })
          .pipe(Effect.flip),
        LimitReached,
      );
    }),
  );
});
