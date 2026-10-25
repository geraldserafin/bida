import {
  type Contribution,
  type EnvelopeId,
  type EnvelopeNotFound,
  Forbidden,
  LastOwner,
  LimitReached,
  MAX_MEMBERS_PER_ENVELOPE,
  type Member,
  MemberNotFound,
  type Role,
  type UserId,
} from "@bida/api-contract";
import { Context, Effect, Layer } from "effect";
import { SqlClient } from "effect/sql";
import { EnvelopesService } from "../envelopes/envelopes.module.ts";
import { MembersRepository } from "./members.repository.ts";

/** Who shares an envelope, with which role, and what they put into it. */
export class MembersService extends Context.Service<
  MembersService,
  {
    /** The members of the envelope (of its parent, for a sub-envelope). */
    list(
      userId: UserId,
      envelopeId: EnvelopeId,
    ): Effect.Effect<ReadonlyArray<Member>, EnvelopeNotFound>;
    setRole(
      userId: UserId,
      envelopeId: EnvelopeId,
      target: UserId,
      role: Role,
    ): Effect.Effect<
      Member,
      EnvelopeNotFound | Forbidden | MemberNotFound | LastOwner
    >;
    /** Owners remove anybody; anybody removes themselves. */
    remove(
      userId: UserId,
      envelopeId: EnvelopeId,
      target: UserId,
    ): Effect.Effect<
      void,
      EnvelopeNotFound | Forbidden | MemberNotFound | LastOwner
    >;
    contributions(
      userId: UserId,
      envelopeId: EnvelopeId,
    ): Effect.Effect<ReadonlyArray<Contribution>, EnvelopeNotFound>;
    /**
     * Lets somebody in (no check who asks: for the invitation that was just
     * approved). Does nothing when they are in already. Fails when the
     * envelope has as many members as it may.
     */
    add(
      envelopeId: EnvelopeId,
      userId: UserId,
      role: Role,
    ): Effect.Effect<Member, LimitReached>;
    /** The owners of a top-level envelope, to tell them about somebody waiting. */
    ownersOf(
      envelopeId: EnvelopeId,
    ): Effect.Effect<ReadonlyArray<{ readonly email: string }>>;
    /** The members of a top-level envelope, without asking who wants to know. */
    membersOf(envelopeId: EnvelopeId): Effect.Effect<ReadonlyArray<Member>>;
  }
>()("bida/members/MembersService") {
  static readonly layer = Layer.effect(
    MembersService,
    Effect.gen(function* () {
      const repo = yield* MembersRepository;
      const envelopes = yield* EnvelopesService;
      const sql = yield* SqlClient.SqlClient;

      /** The top-level envelope the id belongs to, with what the user may do. */
      const topLevel = Effect.fn("MembersService.topLevel")(function* (
        userId: UserId,
        envelopeId: EnvelopeId,
      ) {
        const { envelope, role } = yield* envelopes.access(userId, envelopeId);
        return { id: envelope.parentId ?? envelope.id, role };
      });

      const list = Effect.fn("MembersService.list")(function* (
        userId: UserId,
        envelopeId: EnvelopeId,
      ) {
        const top = yield* topLevel(userId, envelopeId);
        return yield* repo.list(top.id);
      });

      const setRole = Effect.fn("MembersService.setRole")(function* (
        userId: UserId,
        envelopeId: EnvelopeId,
        target: UserId,
        role: Role,
      ) {
        const top = yield* topLevel(userId, envelopeId);
        if (top.role !== "owner") return yield* new Forbidden();
        return yield* Effect.gen(function* () {
          yield* repo.lock(top.id);
          const members = yield* repo.list(top.id);
          const member = members.find((m) => m.userId === target);
          if (member === undefined) {
            return yield* new MemberNotFound({ userId: target });
          }
          const owners = members.filter((m) => m.role === "owner").length;
          if (member.role === "owner" && role !== "owner" && owners <= 1) {
            return yield* new LastOwner();
          }
          yield* repo.setRole(top.id, target, role);
          return { ...member, role };
        }).pipe(sql.withTransaction, Effect.catchTag("SqlError", Effect.die));
      });

      const remove = Effect.fn("MembersService.remove")(function* (
        userId: UserId,
        envelopeId: EnvelopeId,
        target: UserId,
      ) {
        const top = yield* topLevel(userId, envelopeId);
        if (target !== userId && top.role !== "owner") {
          return yield* new Forbidden();
        }
        yield* Effect.gen(function* () {
          yield* repo.lock(top.id);
          const members = yield* repo.list(top.id);
          const member = members.find((m) => m.userId === target);
          if (member === undefined) {
            return yield* new MemberNotFound({ userId: target });
          }
          const owners = members.filter((m) => m.role === "owner").length;
          if (member.role === "owner" && owners <= 1) {
            return yield* new LastOwner();
          }
          yield* repo.remove(top.id, target);
        }).pipe(sql.withTransaction, Effect.catchTag("SqlError", Effect.die));
      });

      const contributions = Effect.fn("MembersService.contributions")(
        function* (userId: UserId, envelopeId: EnvelopeId) {
          const { envelope } = yield* envelopes.access(userId, envelopeId);
          const all = yield* repo.contributions(
            envelope.parentId ?? envelope.id,
          );
          // a sub-envelope shows only its own
          return envelope.parentId === null
            ? all
            : all.filter((c) => c.envelopeId === envelope.id);
        },
      );

      const add = Effect.fn("MembersService.add")(function* (
        envelopeId: EnvelopeId,
        userId: UserId,
        role: Role,
      ) {
        return yield* Effect.gen(function* () {
          yield* repo.lock(envelopeId);
          const members = yield* repo.list(envelopeId);
          const known = members.find((m) => m.userId === userId);
          if (known !== undefined) return known;
          if (members.length >= MAX_MEMBERS_PER_ENVELOPE) {
            return yield* new LimitReached({ limit: MAX_MEMBERS_PER_ENVELOPE });
          }
          yield* repo.insert(envelopeId, userId, role);
          const added = (yield* repo.list(envelopeId)).find(
            (m) => m.userId === userId,
          );
          return yield* added === undefined
            ? Effect.die("member vanished")
            : Effect.succeed(added);
        }).pipe(sql.withTransaction, Effect.catchTag("SqlError", Effect.die));
      });

      return MembersService.of({
        list,
        setRole,
        remove,
        contributions,
        add,
        ownersOf: (envelopeId) =>
          Effect.map(repo.list(envelopeId), (members) =>
            members.filter((m) => m.role === "owner"),
          ),
        membersOf: repo.list,
      });
    }),
  );
}
