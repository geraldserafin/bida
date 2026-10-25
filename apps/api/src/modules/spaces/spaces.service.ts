import {
  DEFAULT_SPACE_ID,
  type SaveSpace,
  Space,
  SpaceId,
  SpaceNotFound,
} from "@bida/api-contract";
import { Context, Effect, Layer, Option, Schema } from "effect";
import { SpacesRepository } from "./spaces.repository.ts";

/** Business rules for spaces. */
export class SpacesService extends Context.Service<
  SpacesService,
  {
    /** The spaces the user is a member of. */
    listFor(userId: string): Effect.Effect<ReadonlyArray<Space>>;
    /** A new space the user owns. */
    createFor(userId: string, input: SaveSpace): Effect.Effect<Space>;
    /** Only members find the space; for everyone else it does not exist. */
    updateFor(
      userId: string,
      id: SpaceId,
      input: SaveSpace,
    ): Effect.Effect<Space, SpaceNotFound>;
    /**
     * The space a request of the user works in: the one the header names, which
     * the user has to be a member of, or their first space without a header.
     */
    resolveFor(
      userId: string,
      id: string | undefined,
    ): Effect.Effect<Space, SpaceNotFound>;
    /**
     * Gives the user the space that holds the data from before accounts
     * existed, if nobody has it yet. `None` when somebody does.
     */
    claimDefault(userId: string): Effect.Effect<Option.Option<Space>>;
  }
>()("bida/spaces/SpacesService") {
  static readonly layer = Layer.effect(
    SpacesService,
    Effect.gen(function* () {
      const repo = yield* SpacesRepository;

      const createFor = Effect.fn("SpacesService.createFor")(function* (
        userId: string,
        input: SaveSpace,
      ) {
        const row = yield* Space.insert.makeEffect(input).pipe(Effect.orDie);
        const space = yield* repo.insert(row);
        yield* repo.addMember(space.id, userId, "owner");
        return space;
      });

      const updateFor = Effect.fn("SpacesService.updateFor")(function* (
        userId: string,
        id: SpaceId,
        input: SaveSpace,
      ) {
        const member = yield* repo.findForUser(userId, id);
        if (Option.isNone(member)) return yield* new SpaceNotFound({ id });
        const updated = yield* repo.update(id, input);
        return yield* Option.match(updated, {
          onNone: () => Effect.fail(new SpaceNotFound({ id })),
          onSome: Effect.succeed,
        });
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
        const found = yield* repo.findForUser(userId, id);
        return yield* Option.match(found, {
          onNone: () => Effect.fail(new SpaceNotFound({ id })),
          onSome: Effect.succeed,
        });
      });

      const claimDefault = Effect.fn("SpacesService.claimDefault")(function* (
        userId: string,
      ) {
        if (yield* repo.defaultSpaceHasMembers) return Option.none<Space>();
        yield* repo.addMember(DEFAULT_SPACE_ID, userId, "owner");
        return yield* repo.findForUser(userId, DEFAULT_SPACE_ID);
      });

      return SpacesService.of({
        listFor: repo.listForUser,
        createFor,
        updateFor,
        resolveFor,
        claimDefault,
      });
    }),
  );
}
