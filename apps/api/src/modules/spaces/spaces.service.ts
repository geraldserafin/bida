import {
  DEFAULT_SPACE_ID,
  Forbidden,
  LastOwner,
  LimitReached,
  MAX_SPACES_PER_USER,
  type Member,
  MemberNotFound,
  PersonalSpace,
  type Role,
  type SaveSpace,
  Space,
  SpaceId,
  SpaceNotEmpty,
  SpaceNotFound,
} from "@bida/api-contract";
import { Context, Effect, Layer, Option, Schema } from "effect";
import { SqlClient } from "effect/sql";
import { type Membership, SpacesRepository } from "./spaces.repository.ts";

/** Business rules for spaces and who is in them. */
export class SpacesService extends Context.Service<
  SpacesService,
  {
    /** The spaces the user is in, the personal one first. */
    listFor(userId: string): Effect.Effect<ReadonlyArray<Membership>>;
    /** The user's space with their role in it; `None` if they are not in it. */
    findFor(
      userId: string,
      id: SpaceId,
    ): Effect.Effect<Option.Option<Membership>>;
    /** The personal space of a new user. */
    createPersonalFor(userId: string, input: SaveSpace): Effect.Effect<Space>;
    /** A new shared space the user owns. */
    createFor(
      userId: string,
      input: SaveSpace,
    ): Effect.Effect<Membership, LimitReached>;
    updateFor(
      userId: string,
      id: SpaceId,
      input: SaveSpace,
    ): Effect.Effect<Membership, SpaceNotFound | Forbidden>;
    deleteFor(
      userId: string,
      id: SpaceId,
    ): Effect.Effect<
      void,
      SpaceNotFound | Forbidden | PersonalSpace | SpaceNotEmpty
    >;
    membersOf(
      userId: string,
      id: SpaceId,
    ): Effect.Effect<ReadonlyArray<Member>, SpaceNotFound>;
    setRoleFor(
      userId: string,
      id: SpaceId,
      target: string,
      role: Role,
    ): Effect.Effect<
      Member,
      SpaceNotFound | Forbidden | MemberNotFound | LastOwner | PersonalSpace
    >;
    removeMemberFor(
      userId: string,
      id: SpaceId,
      target: string,
    ): Effect.Effect<
      void,
      SpaceNotFound | Forbidden | MemberNotFound | LastOwner | PersonalSpace
    >;
    leaveFor(
      userId: string,
      id: SpaceId,
    ): Effect.Effect<void, SpaceNotFound | LastOwner | PersonalSpace>;
    /**
     * The space a request of the user works in: the one the header names, which
     * the user has to be a member of, or their first space without a header.
     */
    resolveFor(
      userId: string,
      id: string | undefined,
    ): Effect.Effect<Membership, SpaceNotFound>;
    /**
     * Gives the user the space that holds the data from before accounts
     * existed, as their personal one, if nobody has it yet. `None` when
     * somebody does.
     */
    claimDefault(userId: string): Effect.Effect<Option.Option<Space>>;
    /** Adds a member to a shared space, refusing past the member limit. */
    addMember(
      spaceId: SpaceId,
      userId: string,
      role: Role,
      limit: number,
    ): Effect.Effect<void, LimitReached>;
  }
>()("bida/spaces/SpacesService") {
  static readonly layer = Layer.effect(
    SpacesService,
    Effect.gen(function* () {
      const repo = yield* SpacesRepository;
      const sql = yield* SqlClient.SqlClient;
      const transaction = <A, E>(effect: Effect.Effect<A, E>) =>
        sql
          .withTransaction(effect)
          .pipe(Effect.catchTag("SqlError", (error) => Effect.die(error)));

      /** The space of the user, or the not-found error everyone gets. */
      const mine = Effect.fn("SpacesService.mine")(function* (
        userId: string,
        id: SpaceId,
      ) {
        const found = yield* repo.findForUser(userId, id);
        return yield* Option.match(found, {
          onNone: () => Effect.fail(new SpaceNotFound({ id })),
          onSome: Effect.succeed,
        });
      });

      const owned = Effect.fn("SpacesService.owned")(function* (
        userId: string,
        id: SpaceId,
      ) {
        const membership = yield* mine(userId, id);
        if (membership.role !== "owner") return yield* new Forbidden();
        return membership;
      });

      const createPersonalFor = Effect.fn("SpacesService.createPersonalFor")(
        function* (userId: string, input: SaveSpace) {
          const row = yield* Space.insert
            .makeEffect({ ...input, kind: "personal" })
            .pipe(Effect.orDie);
          const space = yield* repo.insert(row, userId);
          yield* repo.addMember(space.id, userId, "owner");
          return space;
        },
      );

      const createFor = Effect.fn("SpacesService.createFor")(function* (
        userId: string,
        input: SaveSpace,
      ) {
        if ((yield* repo.countSpacesOf(userId)) >= MAX_SPACES_PER_USER)
          return yield* new LimitReached({ limit: MAX_SPACES_PER_USER });
        const row = yield* Space.insert
          .makeEffect({ ...input, kind: "shared" })
          .pipe(Effect.orDie);
        const space = yield* repo.insert(row);
        yield* repo.addMember(space.id, userId, "owner");
        return { space, role: "owner", memberCount: 1 } satisfies Membership;
      });

      const updateFor = Effect.fn("SpacesService.updateFor")(function* (
        userId: string,
        id: SpaceId,
        input: SaveSpace,
      ) {
        const membership = yield* owned(userId, id);
        const updated = yield* repo.update(id, input);
        const space = yield* Option.match(updated, {
          onNone: () => Effect.fail(new SpaceNotFound({ id })),
          onSome: Effect.succeed,
        });
        return { ...membership, space } satisfies Membership;
      });

      const deleteFor = Effect.fn("SpacesService.deleteFor")(function* (
        userId: string,
        id: SpaceId,
      ) {
        const membership = yield* owned(userId, id);
        if (membership.space.kind === "personal")
          return yield* new PersonalSpace();
        // other people have a say in what is theirs too
        if (membership.memberCount > 1) return yield* new SpaceNotEmpty();
        yield* repo.delete(id);
      });

      const membersOf = Effect.fn("SpacesService.membersOf")(function* (
        userId: string,
        id: SpaceId,
      ) {
        yield* mine(userId, id);
        return yield* repo.members(id);
      });

      /** Changes made under the space's lock, so the owner rule cannot be raced. */
      const guarded = <A, E>(id: SpaceId, effect: Effect.Effect<A, E>) =>
        transaction(Effect.andThen(repo.lock(id), effect));

      const setRoleFor = Effect.fn("SpacesService.setRoleFor")(function* (
        userId: string,
        id: SpaceId,
        target: string,
        role: Role,
      ) {
        return yield* guarded(
          id,
          Effect.gen(function* () {
            const membership = yield* owned(userId, id);
            if (membership.space.kind === "personal")
              return yield* new PersonalSpace();
            const member = yield* repo.findMember(id, target);
            if (Option.isNone(member))
              return yield* new MemberNotFound({ userId: target });
            if (
              member.value.role === "owner" &&
              role === "member" &&
              (yield* repo.countOwners(id)) <= 1
            )
              return yield* new LastOwner();
            const changed = yield* repo.setRole(id, target, role);
            return yield* Option.match(changed, {
              onNone: () => Effect.fail(new MemberNotFound({ userId: target })),
              onSome: Effect.succeed,
            });
          }),
        );
      });

      /** Takes a member out, keeping at least one owner. */
      const withdraw = Effect.fn("SpacesService.withdraw")(function* (
        id: SpaceId,
        target: string,
      ) {
        const member = yield* repo.findMember(id, target);
        if (Option.isNone(member))
          return yield* new MemberNotFound({ userId: target });
        if (member.value.role === "owner" && (yield* repo.countOwners(id)) <= 1)
          return yield* new LastOwner();
        yield* repo.removeMember(id, target);
      });

      const removeMemberFor = Effect.fn("SpacesService.removeMemberFor")(
        function* (userId: string, id: SpaceId, target: string) {
          return yield* guarded(
            id,
            Effect.gen(function* () {
              const membership = yield* owned(userId, id);
              if (membership.space.kind === "personal")
                return yield* new PersonalSpace();
              yield* withdraw(id, target);
            }),
          );
        },
      );

      const leaveFor = Effect.fn("SpacesService.leaveFor")(function* (
        userId: string,
        id: SpaceId,
      ) {
        return yield* guarded(
          id,
          Effect.gen(function* () {
            const membership = yield* mine(userId, id);
            if (membership.space.kind === "personal")
              return yield* new PersonalSpace();
            yield* withdraw(id, userId).pipe(
              // the user is a member (checked above), so this cannot happen
              Effect.catchTag("MemberNotFound", () =>
                Effect.fail(new SpaceNotFound({ id })),
              ),
            );
          }),
        );
      });

      const resolveFor = Effect.fn("SpacesService.resolveFor")(function* (
        userId: string,
        id: string | undefined,
      ) {
        if (id === undefined) {
          const [first] = yield* repo.listForUser(userId);
          return first ?? (yield* new SpaceNotFound({ id: "" }));
        }
        // a header that is not even a uuid cannot name a space
        if (!Schema.is(SpaceId)(id)) return yield* new SpaceNotFound({ id });
        return yield* mine(userId, id);
      });

      const claimDefault = Effect.fn("SpacesService.claimDefault")(function* (
        userId: string,
      ) {
        if (yield* repo.defaultSpaceHasMembers) return Option.none<Space>();
        yield* repo.giveDefaultTo(userId);
        const found = yield* repo.findForUser(userId, DEFAULT_SPACE_ID);
        return Option.map(found, (m) => m.space);
      });

      const addMember = Effect.fn("SpacesService.addMember")(function* (
        spaceId: SpaceId,
        userId: string,
        role: Role,
        limit: number,
      ) {
        return yield* guarded(
          spaceId,
          Effect.gen(function* () {
            if ((yield* repo.countMembers(spaceId)) >= limit)
              return yield* new LimitReached({ limit });
            if ((yield* repo.countSpacesOf(userId)) >= MAX_SPACES_PER_USER)
              return yield* new LimitReached({ limit: MAX_SPACES_PER_USER });
            yield* repo.addMember(spaceId, userId, role);
          }),
        );
      });

      return SpacesService.of({
        listFor: repo.listForUser,
        findFor: repo.findForUser,
        createPersonalFor,
        createFor,
        updateFor,
        deleteFor,
        membersOf,
        setRoleFor,
        removeMemberFor,
        leaveFor,
        resolveFor,
        claimDefault,
        addMember,
      });
    }),
  );
}
