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
    list: Effect.Effect<ReadonlyArray<Space>>;
    create(input: SaveSpace): Effect.Effect<Space>;
    update(id: SpaceId, input: SaveSpace): Effect.Effect<Space, SpaceNotFound>;
    /**
     * The space a request asks for by id. Without an id it is the default
     * space.
     */
    resolve(id: string | undefined): Effect.Effect<Space, SpaceNotFound>;
  }
>()("bida/spaces/SpacesService") {
  static readonly layer = Layer.effect(
    SpacesService,
    Effect.gen(function* () {
      const repo = yield* SpacesRepository;

      const resolve = Effect.fn("SpacesService.resolve")(function* (
        id: string | undefined,
      ) {
        const raw = id ?? DEFAULT_SPACE_ID;
        // a header that is not even a uuid cannot name a space
        if (!Schema.is(SpaceId)(raw))
          return yield* new SpaceNotFound({ id: raw });
        const spaceId = raw;
        const found = yield* repo.findById(spaceId);
        return yield* Option.match(found, {
          onNone: () => Effect.fail(new SpaceNotFound({ id: spaceId })),
          onSome: Effect.succeed,
        });
      });

      const create = Effect.fn("SpacesService.create")(function* (
        input: SaveSpace,
      ) {
        const row = yield* Space.insert.makeEffect(input).pipe(Effect.orDie);
        return yield* repo.insert(row);
      });

      const update = Effect.fn("SpacesService.update")(function* (
        id: SpaceId,
        input: SaveSpace,
      ) {
        const updated = yield* repo.update(id, input);
        return yield* Option.match(updated, {
          onNone: () => Effect.fail(new SpaceNotFound({ id })),
          onSome: Effect.succeed,
        });
      });

      return SpacesService.of({ list: repo.list, create, update, resolve });
    }),
  );
}
