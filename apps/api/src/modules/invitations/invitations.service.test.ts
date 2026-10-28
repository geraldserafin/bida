import {
  AlreadyMember,
  Forbidden,
  type InvitationId,
  InvitationNotFound,
  LimitReached,
  MAX_INVITATIONS_PER_HOUR,
  NotShareable,
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
import {
  EnvelopesModule,
  EnvelopesService,
} from "../envelopes/envelopes.module.ts";
import { MembersModule, MembersService } from "../members/members.module.ts";
import { InvitationsModule, InvitationsService } from "./invitations.module.ts";

const TestLayer = Layer.mergeAll(
  InvitationsModule,
  MembersModule,
  EnvelopesModule,
).pipe(Layer.provideMerge(TestMailer), Layer.provideMerge(DbLive));

const look = { color: "#112233", icon: null } as const;

/** Ann owns Home (with the sub-envelope Rent); Bob and Cid have accounts. */
const setup = Effect.gen(function* () {
  yield* resetDb;
  outbox.length = 0;
  const envelopes = yield* EnvelopesService;
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
  return { ann, bob, cid, home, rent };
});

layer(TestLayer)("InvitationsService", (it) => {
  it.effect("the invited person answers, the owner lets them in", () =>
    Effect.gen(function* () {
      const { ann, bob, home } = yield* setup;
      const invitations = yield* InvitationsService;
      const members = yield* MembersService;
      const envelopes = yield* EnvelopesService;

      const invitation = yield* invitations.invite(
        ann.id,
        home.id,
        `  ${bob.email.toUpperCase()} `,
        "member",
      );
      assert.strictEqual(invitation.email, bob.email);
      assert.strictEqual(invitation.status, "invited");
      assert.strictEqual(invitation.envelopeName, "Home");
      assert.strictEqual(outbox.at(-1)?.to, bob.email);

      const waiting = yield* invitations.mine(bob.email);
      assert.deepStrictEqual(
        waiting.map((i) => i.id),
        [invitation.id],
      );

      // accepting does not let anybody in
      const accepted = yield* invitations.accept(
        bob.id,
        bob.email,
        invitation.id,
      );
      assert.strictEqual(accepted.status, "accepted");
      assert.strictEqual(accepted.acceptedBy, bob.id);
      assert.strictEqual(outbox.at(-1)?.to, ann.email); // the owner is told
      assert.deepStrictEqual(yield* envelopes.list(bob.id), []);
      assert.deepStrictEqual(yield* invitations.mine(bob.email), []);

      const approved = yield* invitations.approve(
        ann.id,
        home.id,
        invitation.id,
      );
      assert.strictEqual(approved.userId, bob.id);
      assert.strictEqual(approved.role, "member");
      assert.strictEqual(outbox.at(-1)?.to, bob.email);
      assert.deepStrictEqual(
        (yield* envelopes.list(bob.id)).map((e) => e.name),
        ["Home", "Rent"],
      );
      assert.strictEqual((yield* members.list(ann.id, home.id)).length, 2);
      assert.deepStrictEqual(
        yield* invitations.forEnvelope(ann.id, home.id),
        [],
      );
    }),
  );

  it.effect(
    "only an owner of a top-level envelope invites, and only the new",
    () =>
      Effect.gen(function* () {
        const { ann, bob, cid, home, rent } = yield* setup;
        const invitations = yield* InvitationsService;
        const members = yield* MembersService;
        yield* members.add(home.id, bob.id, "member");

        assert.instanceOf(
          yield* invitations
            .invite(bob.id, home.id, cid.email, "member")
            .pipe(Effect.flip),
          Forbidden,
        );
        assert.instanceOf(
          yield* invitations
            .invite(ann.id, rent.id, cid.email, "member")
            .pipe(Effect.flip),
          NotShareable,
        );
        assert.instanceOf(
          yield* invitations
            .invite(ann.id, home.id, bob.email, "member")
            .pipe(Effect.flip),
          AlreadyMember,
        );
        // an envelope somebody cannot see does not exist for them
        assert.strictEqual(
          (yield* invitations
            .invite(cid.id, home.id, bob.email, "member")
            .pipe(Effect.flip))._tag,
          "EnvelopeNotFound",
        );
      }),
  );

  it.effect("inviting again renews the invitation with the new role", () =>
    Effect.gen(function* () {
      const { ann, bob, home } = yield* setup;
      const invitations = yield* InvitationsService;
      const first = yield* invitations.invite(
        ann.id,
        home.id,
        bob.email,
        "member",
      );
      const second = yield* invitations.invite(
        ann.id,
        home.id,
        bob.email,
        "owner",
      );
      assert.strictEqual(second.id, first.id);
      assert.strictEqual(second.role, "owner");
      assert.strictEqual(
        (yield* invitations.forEnvelope(ann.id, home.id)).length,
        1,
      );
    }),
  );

  it.effect("somebody else cannot answer the invitation", () =>
    Effect.gen(function* () {
      const { ann, bob, cid, home } = yield* setup;
      const invitations = yield* InvitationsService;
      const invitation = yield* invitations.invite(
        ann.id,
        home.id,
        bob.email,
        "member",
      );
      assert.instanceOf(
        yield* invitations
          .accept(cid.id, cid.email, invitation.id)
          .pipe(Effect.flip),
        InvitationNotFound,
      );
      assert.instanceOf(
        yield* invitations.decline(cid.email, invitation.id).pipe(Effect.flip),
        InvitationNotFound,
      );
      // and nobody is let in before they accepted
      assert.instanceOf(
        yield* invitations
          .approve(ann.id, home.id, invitation.id)
          .pipe(Effect.flip),
        InvitationNotFound,
      );
    }),
  );

  it.effect("a declined invitation is gone", () =>
    Effect.gen(function* () {
      const { ann, bob, home } = yield* setup;
      const invitations = yield* InvitationsService;
      const invitation = yield* invitations.invite(
        ann.id,
        home.id,
        bob.email,
        "member",
      );
      yield* invitations.decline(bob.email, invitation.id);
      assert.deepStrictEqual(yield* invitations.mine(bob.email), []);
      assert.instanceOf(
        yield* invitations
          .accept(bob.id, bob.email, invitation.id)
          .pipe(Effect.flip),
        InvitationNotFound,
      );
    }),
  );

  it.effect("an owner revokes an invitation, also one that was accepted", () =>
    Effect.gen(function* () {
      const { ann, bob, cid, home } = yield* setup;
      const invitations = yield* InvitationsService;
      const first = yield* invitations.invite(
        ann.id,
        home.id,
        bob.email,
        "member",
      );
      yield* invitations.revoke(ann.id, home.id, first.id);
      assert.deepStrictEqual(yield* invitations.mine(bob.email), []);

      const second = yield* invitations.invite(
        ann.id,
        home.id,
        cid.email,
        "member",
      );
      yield* invitations.accept(cid.id, cid.email, second.id);
      yield* invitations.revoke(ann.id, home.id, second.id);
      assert.instanceOf(
        yield* invitations
          .approve(ann.id, home.id, second.id)
          .pipe(Effect.flip),
        InvitationNotFound,
      );
    }),
  );

  it.effect("an invitation that ran out cannot be answered or approved", () =>
    Effect.gen(function* () {
      const { ann, bob, home } = yield* setup;
      const invitations = yield* InvitationsService;
      const sql = yield* SqlClient.SqlClient;
      const invitation = yield* invitations.invite(
        ann.id,
        home.id,
        bob.email,
        "member",
      );
      yield* invitations.accept(bob.id, bob.email, invitation.id);
      yield* sql`UPDATE invitations SET expires_at = now() - interval '1 minute'`;

      assert.instanceOf(
        yield* invitations
          .approve(ann.id, home.id, invitation.id)
          .pipe(Effect.flip),
        InvitationNotFound,
      );
      assert.deepStrictEqual(
        yield* invitations.forEnvelope(ann.id, home.id),
        [],
      );
    }),
  );

  it.effect(
    "an invitation of another envelope is not found through this one",
    () =>
      Effect.gen(function* () {
        const { ann, bob, home } = yield* setup;
        const invitations = yield* InvitationsService;
        const envelopes = yield* EnvelopesService;
        const other = yield* envelopes.create(ann.id, {
          parentId: null,
          name: "Other",
          ...look,
        });
        const invitation = yield* invitations.invite(
          ann.id,
          other.id,
          bob.email,
          "member",
        );
        assert.instanceOf(
          yield* invitations
            .revoke(ann.id, home.id, invitation.id as InvitationId)
            .pipe(Effect.flip),
          InvitationNotFound,
        );
      }),
  );

  it.effect("a person sends only so many invitations in an hour", () =>
    Effect.gen(function* () {
      const { ann, home } = yield* setup;
      const invitations = yield* InvitationsService;
      const envelopes = yield* EnvelopesService;
      const other = yield* envelopes.create(ann.id, {
        parentId: null,
        name: "Other",
        ...look,
      });
      // spread over two envelopes, so neither is full
      for (let i = 0; i < MAX_INVITATIONS_PER_HOUR; i++) {
        yield* invitations.invite(
          ann.id,
          i % 2 === 0 ? home.id : other.id,
          `person${i}@example.com`,
          "member",
        );
      }
      const error = yield* invitations
        .invite(ann.id, home.id, "one-more@example.com", "member")
        .pipe(Effect.flip);
      assert.instanceOf(error, LimitReached);
      assert.strictEqual(error.limit, MAX_INVITATIONS_PER_HOUR);
    }),
  );
});
