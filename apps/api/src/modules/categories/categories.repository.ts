import { Category, type CategoryId, CategoryInUse } from "@bida/api-contract";
import { Context, Effect, Layer, Option, Schema } from "effect";
import { SqlClient, SqlModel, SqlSchema } from "effect/sql";

/** SQL only: no business rules, infrastructure failures are defects. */
export class CategoriesRepository extends Context.Service<
  CategoriesRepository,
  {
    list: Effect.Effect<ReadonlyArray<Category>>;
    findById(id: CategoryId): Effect.Effect<Option.Option<Category>>;
    insert(input: typeof Category.insert.Type): Effect.Effect<Category>;
    /** `None` when the row does not exist. */
    update(
      input: typeof Category.update.Type,
    ): Effect.Effect<Option.Option<Category>>;
    /** Fails with `CategoryInUse` when a foreign key still points at the row. */
    remove(id: CategoryId): Effect.Effect<void, CategoryInUse>;
  }
>()("bida/categories/CategoriesRepository") {
  static readonly layer = Layer.effect(
    CategoriesRepository,
    Effect.gen(function* () {
      const sql = yield* SqlClient.SqlClient;
      const crud = yield* SqlModel.makeRepository(Category, {
        tableName: "categories",
        spanPrefix: "CategoriesRepository",
        idColumn: "id",
      });

      const listAll = SqlSchema.findAll({
        Request: Schema.Void,
        Result: Category,
        execute: () => sql`SELECT * FROM categories ORDER BY lower(name)`,
      });

      // crud.update treats a missing row as a defect, we want None instead
      const updateOne = SqlSchema.findOneOption({
        Request: Category.update,
        Result: Category,
        execute: (request) =>
          sql`UPDATE categories SET ${sql.update(request, ["id"])}
            WHERE id = ${request.id} RETURNING *`,
      });

      return CategoriesRepository.of({
        list: listAll().pipe(
          Effect.orDie,
          Effect.withSpan("CategoriesRepository.list"),
        ),
        findById: (id) =>
          crud.findById(id).pipe(
            Effect.map(Option.some),
            Effect.catchTag("NoSuchElementError", () =>
              Effect.succeed(Option.none()),
            ),
            Effect.orDie,
          ),
        insert: (input) => crud.insert(input).pipe(Effect.orDie),
        update: (input) => updateOne(input).pipe(Effect.orDie),
        remove: (id) =>
          crud.delete(id).pipe(
            Effect.catchTag("SqlError", (error) =>
              error.reason._tag === "ConstraintError"
                ? Effect.fail(new CategoryInUse({ id }))
                : Effect.die(error),
            ),
            Effect.catchTag("SchemaError", Effect.die),
          ),
      });
    }),
  );
}
