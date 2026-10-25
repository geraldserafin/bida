import { Category, type CategoryId } from "@bida/api-contract";
import { Effect, Layer, Option } from "effect";
import { CategoriesRepository } from "./categories.repository.ts";

/** In-memory repository for service and http tests, no database needed. */
export const CategoriesRepositoryMemory = Layer.sync(
  CategoriesRepository,
  () => {
    const rows = new Map<CategoryId, Category>();
    return CategoriesRepository.of({
      list: Effect.sync(() => [...rows.values()]),
      findById: (id) => Effect.sync(() => Option.fromNullishOr(rows.get(id))),
      insert: (input) =>
        Effect.sync(() => {
          const category = new Category(input);
          rows.set(category.id, category);
          return category;
        }),
      update: (input) =>
        Effect.sync(() => {
          const existing = rows.get(input.id);
          if (existing === undefined) return Option.none();
          const updated = new Category({ ...existing, ...input });
          rows.set(updated.id, updated);
          return Option.some(updated);
        }),
      remove: (id) => Effect.sync(() => void rows.delete(id)),
    });
  },
);
