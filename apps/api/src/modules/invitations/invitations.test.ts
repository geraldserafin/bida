import {
  AlreadyMember,
  Forbidden,
  InvitationId,
  InvitationNotFound,
  LimitReached,
  MAX_INVITATIONS_PER_HOUR,
  MAX_MEMBERS_PER_SPACE,
  PersonalSpace,
  SpaceNotFound,
} from "@bida/api-contract";
import { assert, layer } from "@effect/vitest";
import { Effect, Layer } from "effect";
import { SqlClient } from "effect/sql";
import { DbLive } from "../../platform/db.ts";
import {
  insertUser,
  outbox,
  resetDb,
  TestMailer,
} from "../../platform/testing.ts";
import { SpacesModule, SpacesService } from "../spaces/spaces.module.ts";
import { InvitationsModule, InvitationsService } from "./invitations.module.ts";

const TestLayer = Layer.mergeAll(InvitationsModule, SpacesModule).pipe(
  Layer.provideMerge(TestMailer),
  Layer.provideMerge(DbLive),
);

/** A shared space with its owner, and two people who may be invited. */
const setup = Effect.gen(function* () {
  yield* resetDb;
  outbox.length = 0;
  const spaces = yield* SpacesService;
  const invitations = yield* InvitationsService;
  const owner = yield* insertUser("owner@example.com");
  const ann = yield* insertUser("ann@example.com");
  const bob = yield* insertUser("bob@example.com");
  const { space } = yield* spaces.createFor(owner.id, {
    name: "Home",
    defaultCurrency: "PLN",
  });
  return { spaces, invitations, owner, ann, bob, space };
});

layer(TestLayer)("invitations", (it) => {
  it.effect(
    "an invitation is answered, then approved, and the person is in",
    () =>
      Effect.gen(function* () {
        const { spaces, invitations, owner, ann, space } = yield* setup;

        const invited = yield* invitations.invite(
          owner.id,
          space.id,
          " Ann@Example.com ",
          "member",
        );
        assert.strictEqual(invited.email, "ann@example.com");
        assert.strictEqual(invited.status, "invited");
        assert.strictEqual(invited.spaceName, "Home");
        assert.deepStrictEqual(
          outbox.map((m) => m.to),
          ["ann@example.com"],
        );
        assert.include(outbox[0]?.subject ?? "", "Home");

        const mine = yield* invitations.mine("ann@example.com");
        assert.deepStrictEqual(
          mine.map((i) => i.id),
          [invited.id],
        );
        assert.deepStrictEqual(yield* invitations.mine("bob@example.com"), []);

        // accepting tells the owners but does not let the person in
        outbox.length = 0;
        const accepted = yield* invitations.accept(
          ann.id,
          "ann@example.com",
          invited.id,
        );
        assert.strictEqual(accepted.status, "accepted");
        assert.deepStrictEqual(
          outbox.map((m) => m.to),
          ["owner@example.com"],
        );
        assert.deepStrictEqual(yield* spaces.listFor(ann.id), []);
        assert.deepStrictEqual(yield* invitations.mine("ann@example.com"), []);

        const member = yield* invitations.approve(
          owner.id,
          space.id,
          invited.id,
        );
        assert.strictEqual(member.email, "ann@example.com");
        assert.strictEqual(member.role, "member");
        assert.strictEqual((yield* spaces.listFor(ann.id)).length, 1);
        assert.deepStrictEqual(
          yield* invitations.forSpace(owner.id, space.id),
          [],
        );
        assert.include(outbox.at(-1)?.to ?? "", "ann@example.com");
      }),
  );

  it.effect("only owners invite, list, revoke and approve", () =>
    Effect.gen(function* () {
      const { spaces, invitations, owner, ann, bob, space } = yield* setup;
      const invited = yield* invitations.invite(
        owner.id,
        space.id,
        "bob@example.com",
        "member",
      );
      yield* spaces.addMember(space.id, ann.id, "member", 10);

      for (const error of [
        yield* invitations
          .invite(ann.id, space.id, "x@example.com", "member")
          .pipe(Effect.flip),
        yield* invitations.forSpace(ann.id, space.id).pipe(Effect.flip),
        yield* invitations
          .revoke(ann.id, space.id, invited.id)
          .pipe(Effect.flip),
        yield* invitations
          .approve(ann.id, space.id, invited.id)
          .pipe(Effect.flip),
      ])
        assert.instanceOf(error, Forbidden);

      // somebody outside the space cannot even tell it exists
      assert.instanceOf(
        yield* invitations.forSpace(bob.id, space.id).pipe(Effect.flip),
        SpaceNotFound,
      );
    }),
  );

  it.effect("personal spaces take no invitations", () =>
    Effect.gen(function* () {
      const { spaces, invitations, owner } = yield* setup;
      const personal = yield* spaces.createPersonalFor(owner.id, {
        name: "Mine",
        defaultCurrency: "PLN",
      });
      assert.instanceOf(
        yield* invitations
          .invite(owner.id, personal.id, "ann@example.com", "member")
          .pipe(Effect.flip),
        PersonalSpace,
      );
    }),
  );

  it.effect(
    "a member cannot be invited again, an invited address is renewed",
    () =>
      Effect.gen(function* () {
        const { spaces, invitations, owner, ann, space } = yield* setup;

        const first = yield* invitations.invite(
          owner.id,
          space.id,
          "bob@example.com",
          "member",
        );
        const again = yield* invitations.invite(
          owner.id,
          space.id,
          "BOB@example.com",
          "owner",
        );
        assert.strictEqual(again.id, first.id);
        assert.strictEqual(again.role, "owner");
        assert.strictEqual(
          (yield* invitations.forSpace(owner.id, space.id)).length,
          1,
        );

        yield* spaces.addMember(space.id, ann.id, "member", 10);
        assert.instanceOf(
          yield* invitations
            .invite(owner.id, space.id, "ann@example.com", "member")
            .pipe(Effect.flip),
          AlreadyMember,
        );
      }),
  );

  it.effect("somebody else's address cannot answer an invitation", () =>
    Effect.gen(function* () {
      const { invitations, owner, bob, space } = yield* setup;
      const invited = yield* invitations.invite(
        owner.id,
        space.id,
        "ann@example.com",
        "member",
      );

      assert.instanceOf(
        yield* invitations
          .accept(bob.id, "bob@example.com", invited.id)
          .pipe(Effect.flip),
        InvitationNotFound,
      );
      assert.instanceOf(
        yield* invitations
          .decline("bob@example.com", invited.id)
          .pipe(Effect.flip),
        InvitationNotFound,
      );
      assert.instanceOf(
        yield* invitations
          .accept(
            bob.id,
            "bob@example.com",
            InvitationId.make("019845e1-682f-4b02-a706-3b2422d13aec"),
          )
          .pipe(Effect.flip),
        InvitationNotFound,
      );
    }),
  );

  it.effect(
    "an invitation can be declined or revoked, and then no longer works",
    () =>
      Effect.gen(function* () {
        const { invitations, owner, ann, bob, space } = yield* setup;
        const toAnn = yield* invitations.invite(
          owner.id,
          space.id,
          "ann@example.com",
          "member",
        );
        const toBob = yield* invitations.invite(
          owner.id,
          space.id,
          "bob@example.com",
          "member",
        );

        yield* invitations.decline("ann@example.com", toAnn.id);
        yield* invitations.revoke(owner.id, space.id, toBob.id);
        assert.deepStrictEqual(
          yield* invitations.forSpace(owner.id, space.id),
          [],
        );

        assert.instanceOf(
          yield* invitations
            .accept(ann.id, "ann@example.com", toAnn.id)
            .pipe(Effect.flip),
          InvitationNotFound,
        );
        assert.instanceOf(
          yield* invitations
            .accept(bob.id, "bob@example.com", toBob.id)
            .pipe(Effect.flip),
          InvitationNotFound,
        );

        // after a decline the address can be invited again
        yield* invitations.invite(
          owner.id,
          space.id,
          "ann@example.com",
          "member",
        );
      }),
  );

  it.effect("an owner can turn down somebody who accepted", () =>
    Effect.gen(function* () {
      const { spaces, invitations, owner, ann, space } = yield* setup;
      const invited = yield* invitations.invite(
        owner.id,
        space.id,
        "ann@example.com",
        "member",
      );
      yield* invitations.accept(ann.id, "ann@example.com", invited.id);

      yield* invitations.revoke(owner.id, space.id, invited.id);

      assert.instanceOf(
        yield* invitations
          .approve(owner.id, space.id, invited.id)
          .pipe(Effect.flip),
        InvitationNotFound,
      );
      assert.deepStrictEqual(yield* spaces.listFor(ann.id), []);
    }),
  );

  it.effect("an invitation has to be accepted before it is approved", () =>
    Effect.gen(function* () {
      const { invitations, owner, space } = yield* setup;
      const invited = yield* invitations.invite(
        owner.id,
        space.id,
        "ann@example.com",
        "member",
      );

      assert.instanceOf(
        yield* invitations
          .approve(owner.id, space.id, invited.id)
          .pipe(Effect.flip),
        InvitationNotFound,
      );
    }),
  );

  it.effect("an expired invitation can be neither answered nor approved", () =>
    Effect.gen(function* () {
      const { invitations, owner, ann, bob, space } = yield* setup;
      const sql = yield* SqlClient.SqlClient;
      const toAnn = yield* invitations.invite(
        owner.id,
        space.id,
        "ann@example.com",
        "member",
      );
      const toBob = yield* invitations.invite(
        owner.id,
        space.id,
        "bob@example.com",
        "member",
      );
      yield* invitations.accept(bob.id, "bob@example.com", toBob.id);
      yield* sql`UPDATE invitations SET expires_at = now() - interval '1 second'`;

      assert.deepStrictEqual(yield* invitations.mine("ann@example.com"), []);
      assert.deepStrictEqual(
        yield* invitations.forSpace(owner.id, space.id),
        [],
      );
      assert.instanceOf(
        yield* invitations
          .accept(ann.id, "ann@example.com", toAnn.id)
          .pipe(Effect.flip),
        InvitationNotFound,
      );
      assert.instanceOf(
        yield* invitations
          .approve(owner.id, space.id, toBob.id)
          .pipe(Effect.flip),
        InvitationNotFound,
      );
      // inviting the address again starts a fresh invitation
      const renewed = yield* invitations.invite(
        owner.id,
        space.id,
        "ann@example.com",
        "member",
      );
      assert.strictEqual(renewed.id, toAnn.id);
      assert.strictEqual(
        (yield* invitations.mine("ann@example.com")).length,
        1,
      );
    }),
  );

  it.effect("limits the places in a space, counting open invitations", () =>
    Effect.gen(function* () {
      const { invitations, owner, space } = yield* setup;
      // the owner takes one place
      for (let i = 1; i < MAX_MEMBERS_PER_SPACE; i++)
        yield* invitations.invite(
          owner.id,
          space.id,
          `p${i}@example.com`,
          "member",
        );

      assert.instanceOf(
        yield* invitations
          .invite(owner.id, space.id, "one-more@example.com", "member")
          .pipe(Effect.flip),
        LimitReached,
      );
      // renewing one that is open still works
      yield* invitations.invite(owner.id, space.id, "p1@example.com", "owner");
    }),
  );

  it.effect("limits how many invitations one person sends in an hour", () =>
    Effect.gen(function* () {
      const { spaces, invitations, owner } = yield* setup;
      // spread over spaces, so only the hourly limit can stop it
      const ids = [];
      for (let i = 0; i < 3; i++) {
        const { space } = yield* spaces.createFor(owner.id, {
          name: `S${i}`,
          defaultCurrency: "PLN",
        });
        ids.push(space.id);
      }
      for (let i = 0; i < MAX_INVITATIONS_PER_HOUR; i++)
        yield* invitations.invite(
          owner.id,
          ids[i % 3] as never,
          `q${i}@example.com`,
          "member",
        );

      assert.instanceOf(
        yield* invitations
          .invite(owner.id, ids[0] as never, "late@example.com", "member")
          .pipe(Effect.flip),
        LimitReached,
      );
    }),
  );
});
