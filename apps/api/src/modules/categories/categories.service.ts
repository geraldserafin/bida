import {
  Category,
  type CategoryId,
  type CategoryInUse,
  CategoryNotFound,
} from "@bida/api-contract";
import { Context, Effect, Layer, Option } from "effect";
import type { InSpace } from "../../platform/space.ts";
import { CategoriesRepository } from "./categories.repository.ts";

/** Business rules for categories. Knows nothing about HTTP or SQL. */
export class CategoriesService extends Context.Service<
  CategoriesService,
  {
    list: InSpace<ReadonlyArray<Category>>;
    get(id: CategoryId): InSpace<Category, CategoryNotFound>;
    create(input: typeof Category.jsonCreate.Type): InSpace<Category>;
    update(
      id: CategoryId,
      input: typeof Category.jsonUpdate.Type,
    ): InSpace<Category, CategoryNotFound>;
    remove(id: CategoryId): InSpace<void, CategoryNotFound | CategoryInUse>;
  }
>()("bida/categories/CategoriesService") {
  static readonly layer = Layer.effect(
    CategoriesService,
    Effect.gen(function* () {
      const repo = yield* CategoriesRepository;

      const get = Effect.fn("CategoriesService.get")(function* (
        id: CategoryId,
      ) {
        const found = yield* repo.findById(id);
        return yield* Option.match(found, {
          onNone: () => Effect.fail(new CategoryNotFound({ id })),
          onSome: Effect.succeed,
        });
      });

      const create = Effect.fn("CategoriesService.create")(function* (
        input: typeof Category.jsonCreate.Type,
      ) {
        const row = yield* Category.insert.makeEffect(input).pipe(Effect.orDie);
        return yield* repo.insert(row);
      });

      const update = Effect.fn("CategoriesService.update")(function* (
        id: CategoryId,
        input: typeof Category.jsonUpdate.Type,
      ) {
        const row = yield* Category.update
          .makeEffect({ id, ...input })
          .pipe(Effect.orDie);
        const updated = yield* repo.update(row);
        return yield* Option.match(updated, {
          onNone: () => Effect.fail(new CategoryNotFound({ id })),
          onSome: Effect.succeed,
        });
      });

      const remove = Effect.fn("CategoriesService.remove")(function* (
        id: CategoryId,
      ) {
        yield* get(id);
        yield* repo.remove(id);
      });

      return CategoriesService.of({
        list: repo.list,
        get,
        create,
        update,
        remove,
      });
    }),
  );
}
