import {
  Allocation,
  type AllocationId,
  AllocationNotFound,
  type CreateAllocation,
  type CreateEnvelope,
  Envelope,
  type EnvelopeId,
  EnvelopeNotFound,
  Forbidden,
  NotEnoughMoney,
  ParentMustBeTopLevel,
  type UpdateAllocation,
  type UpdateEnvelope,
  type UserId,
} from "@bida/api-contract";
import { Context, Effect, Layer, Option } from "effect";
import { SqlClient } from "effect/sql";
import {
  type AllocationFilter,
  EnvelopesRepository,
  type MemberRole,
} from "./envelopes.repository.ts";

/** An envelope with what the user may do with it. */
export interface EnvelopeAccess {
  readonly envelope: Envelope;
  readonly role: MemberRole;
}

export interface ListAllocations {
  readonly envelopeId?: EnvelopeId | undefined;
  readonly from?: string | undefined;
  readonly to?: string | undefined;
}

/** Business rules for envelopes and for the money put into them. */
export class EnvelopesService extends Context.Service<
  EnvelopesService,
  {
    list(userId: UserId): Effect.Effect<ReadonlyArray<Envelope>>;
    get(
      userId: UserId,
      id: EnvelopeId,
    ): Effect.Effect<Envelope, EnvelopeNotFound>;
    /** The envelope and the role of the user in it; 404 when they cannot see it. */
    access(
      userId: UserId,
      id: EnvelopeId,
    ): Effect.Effect<EnvelopeAccess, EnvelopeNotFound>;
    /**
     * The envelopes that make up what the user asks about: the one they name
     * with its sub-envelopes, or every envelope they can see.
     */
    scope(
      userId: UserId,
      envelopeId: EnvelopeId | undefined,
    ): Effect.Effect<ReadonlyArray<EnvelopeId>, EnvelopeNotFound>;
    create(
      userId: UserId,
      input: CreateEnvelope,
    ): Effect.Effect<
      Envelope,
      EnvelopeNotFound | ParentMustBeTopLevel | Forbidden
    >;
    update(
      userId: UserId,
      id: EnvelopeId,
      input: UpdateEnvelope,
    ): Effect.Effect<Envelope, EnvelopeNotFound | Forbidden>;
    remove(
      userId: UserId,
      id: EnvelopeId,
    ): Effect.Effect<void, EnvelopeNotFound | Forbidden>;

    listAllocations(
      userId: UserId,
      filter: ListAllocations,
    ): Effect.Effect<ReadonlyArray<Allocation>, EnvelopeNotFound>;
    /**
     * `rule` says which allocation rule made it and for which stretch (its
     * first day), when an allocation rule did.
     */
    createAllocation(
      userId: UserId,
      input: CreateAllocation,
      rule?: { readonly ruleId: string; readonly month: string },
    ): Effect.Effect<Allocation, EnvelopeNotFound | NotEnoughMoney>;
    /** Of the rules, those that already made an allocation for the stretch. */
    appliedRuleIds(
      ruleIds: ReadonlyArray<string>,
      month: string,
    ): Effect.Effect<ReadonlySet<string>>;
    updateAllocation(
      userId: UserId,
      id: AllocationId,
      input: UpdateAllocation,
    ): Effect.Effect<Allocation, AllocationNotFound | NotEnoughMoney>;
    removeAllocation(
      userId: UserId,
      id: AllocationId,
    ): Effect.Effect<void, AllocationNotFound | NotEnoughMoney>;
  }
>()("bida/envelopes/EnvelopesService") {
  static readonly layer = Layer.effect(
    EnvelopesService,
    Effect.gen(function* () {
      const repo = yield* EnvelopesRepository;
      const sql = yield* SqlClient.SqlClient;

      const list = repo.listFor;

      const access = Effect.fn("EnvelopesService.access")(function* (
        userId: UserId,
        id: EnvelopeId,
      ) {
        const envelope = yield* repo.findFor(userId, id);
        const role = yield* repo.roleOf(userId, id);
        if (Option.isNone(envelope) || Option.isNone(role)) {
          return yield* new EnvelopeNotFound({ id });
        }
        return { envelope: envelope.value, role: role.value };
      });

      const get = (userId: UserId, id: EnvelopeId) =>
        Effect.map(access(userId, id), (found) => found.envelope);

      const scope = Effect.fn("EnvelopesService.scope")(function* (
        userId: UserId,
        envelopeId: EnvelopeId | undefined,
      ) {
        if (envelopeId === undefined) {
          return (yield* repo.listFor(userId)).map((e) => e.id);
        }
        const { envelope } = yield* access(userId, envelopeId);
        return envelope.parentId === null
          ? [envelope.id, ...(yield* repo.childIds(envelope.id))]
          : [envelope.id];
      });

      const create = Effect.fn("EnvelopesService.create")(function* (
        userId: UserId,
        input: CreateEnvelope,
      ) {
        if (input.parentId !== null) {
          const parent = yield* access(userId, input.parentId);
          if (parent.envelope.parentId !== null) {
            return yield* new ParentMustBeTopLevel({
              parentId: input.parentId,
            });
          }
          if (parent.role !== "owner") return yield* new Forbidden();
        }
        const row = yield* Envelope.insert
          .makeEffect({ ...input, ownerId: userId })
          .pipe(Effect.orDie);
        return yield* Effect.gen(function* () {
          const created = yield* repo.insert(row);
          if (created.parentId === null) {
            yield* repo.addMember(created.id, userId, "owner");
          }
          return created;
        }).pipe(sql.withTransaction, Effect.orDie);
      });

      const update = Effect.fn("EnvelopesService.update")(function* (
        userId: UserId,
        id: EnvelopeId,
        input: UpdateEnvelope,
      ) {
        const { role } = yield* access(userId, id);
        if (role !== "owner") return yield* new Forbidden();
        const updated = yield* repo.update(id, input);
        return yield* Option.match(updated, {
          onNone: () => Effect.fail(new EnvelopeNotFound({ id })),
          onSome: Effect.succeed,
        });
      });

      const remove = Effect.fn("EnvelopesService.remove")(function* (
        userId: UserId,
        id: EnvelopeId,
      ) {
        const { role } = yield* access(userId, id);
        if (role !== "owner") return yield* new Forbidden();
        yield* repo.remove(id);
      });

      const listAllocations = Effect.fn("EnvelopesService.listAllocations")(
        function* (userId: UserId, filter: ListAllocations) {
          const envelopeIds = yield* scope(userId, filter.envelopeId);
          const query: AllocationFilter = {
            envelopeIds,
            from: filter.from,
            to: filter.to,
          };
          return yield* repo.listAllocations(query);
        },
      );

      /**
       * Refuses a change of `delta` to the money the user put into the
       * envelope when it would take out more than there is:
       *
       *  - from a top-level envelope: more than the user has not assigned to
       *  its sub-envelopes yet, or more than is free in it;
       *  - into a sub-envelope: more than the user put into its parent and has
       *    not assigned yet;
       *  - out of a sub-envelope: more than the user assigned to it or than
       *    it has left.
       *
       * Taking money into a top-level envelope never fails: the pool of the
       * user may go below zero.
       */
      const checkChange = Effect.fn("EnvelopesService.checkChange")(function* (
        userId: UserId,
        envelope: Envelope,
        delta: number,
      ) {
        if (delta === 0) return;
        if (envelope.parentId === null) {
          if (delta > 0) return;
          const own = yield* repo.totals(envelope.id, userId);
          const kids = yield* repo.childTotals(envelope.id, userId);
          const available = Math.min(
            own.allocatedByUser - kids.allocatedByUser,
            own.allocated - kids.allocated - own.spent,
          );
          if (-delta > available) {
            return yield* new NotEnoughMoney({
              envelopeId: envelope.id,
              availableMinor: Math.max(0, available),
            });
          }
          return;
        }
        if (delta > 0) {
          const parent = yield* repo.totals(envelope.parentId, userId);
          const kids = yield* repo.childTotals(envelope.parentId, userId);
          const unassigned = parent.allocatedByUser - kids.allocatedByUser;
          if (delta > unassigned) {
            return yield* new NotEnoughMoney({
              envelopeId: envelope.parentId,
              availableMinor: Math.max(0, unassigned),
            });
          }
          return;
        }
        const own = yield* repo.totals(envelope.id, userId);
        const available = Math.min(
          own.allocatedByUser,
          own.allocated - own.spent,
        );
        if (-delta > available) {
          return yield* new NotEnoughMoney({
            envelopeId: envelope.id,
            availableMinor: Math.max(0, available),
          });
        }
      });

      const topLevelOf = (envelope: Envelope): EnvelopeId =>
        envelope.parentId ?? envelope.id;

      const createAllocation = Effect.fn("EnvelopesService.createAllocation")(
        function* (
          userId: UserId,
          input: CreateAllocation,
          rule?: { readonly ruleId: string; readonly month: string },
        ) {
          const { envelope } = yield* access(userId, input.envelopeId);
          const row = yield* Allocation.insert
            .makeEffect({ ...input, userId })
            .pipe(Effect.orDie);
          return yield* Effect.gen(function* () {
            yield* repo.lock(topLevelOf(envelope));
            yield* checkChange(userId, envelope, input.amountMinor);
            return yield* repo.insertAllocation(row, rule);
          }).pipe(sql.withTransaction, Effect.catchTag("SqlError", Effect.die));
        },
      );

      const ownAllocation = Effect.fn("EnvelopesService.ownAllocation")(
        function* (userId: UserId, id: AllocationId) {
          const found = yield* repo.findOwnAllocation(userId, id);
          if (Option.isNone(found))
            return yield* new AllocationNotFound({ id });
          // the allocation is the user's own, so the envelope is visible to them
          const envelope = yield* repo.findFor(userId, found.value.envelopeId);
          if (Option.isNone(envelope)) {
            return yield* new AllocationNotFound({ id });
          }
          return { allocation: found.value, envelope: envelope.value };
        },
      );

      const updateAllocation = Effect.fn("EnvelopesService.updateAllocation")(
        function* (userId: UserId, id: AllocationId, input: UpdateAllocation) {
          return yield* Effect.gen(function* () {
            const { allocation, envelope } = yield* ownAllocation(userId, id);
            yield* repo.lock(topLevelOf(envelope));
            yield* checkChange(
              userId,
              envelope,
              input.amountMinor - allocation.amountMinor,
            );
            const updated = yield* repo.updateAllocation(id, input);
            return yield* Option.match(updated, {
              onNone: () => Effect.fail(new AllocationNotFound({ id })),
              onSome: Effect.succeed,
            });
          }).pipe(sql.withTransaction, Effect.catchTag("SqlError", Effect.die));
        },
      );

      const removeAllocation = Effect.fn("EnvelopesService.removeAllocation")(
        function* (userId: UserId, id: AllocationId) {
          yield* Effect.gen(function* () {
            const { allocation, envelope } = yield* ownAllocation(userId, id);
            yield* repo.lock(topLevelOf(envelope));
            yield* checkChange(userId, envelope, -allocation.amountMinor);
            yield* repo.removeAllocation(id);
          }).pipe(sql.withTransaction, Effect.catchTag("SqlError", Effect.die));
        },
      );

      return EnvelopesService.of({
        list,
        get,
        access,
        scope,
        create,
        update,
        remove,
        listAllocations,
        createAllocation,
        appliedRuleIds: repo.appliedRuleIds,
        updateAllocation,
        removeAllocation,
      });
    }),
  );
}
