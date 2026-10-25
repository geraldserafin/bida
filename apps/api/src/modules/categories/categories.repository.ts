import {
  Category,
  type CategoryId,
  CategoryInUse,
  CurrentSpace,
} from "@bida/api-contract";
import { Context, Effect, Layer, type Option, Schema } from "effect";
import { SqlClient, SqlSchema } from "effect/sql";
import type { InSpace } from "../../platform/space.ts";

/** SQL only: no business rules, infrastructure failures are defects. */
export class CategoriesRepository extends Context.Service<
  CategoriesRepository,
  {
    list: InSpace<ReadonlyArray<Category>>;
    findById(id: CategoryId): InSpace<Option.Option<Category>>;
    insert(input: typeof Category.insert.Type): InSpace<Category>;
    /** `None` when the row does not exist. */
    update(
      input: typeof Category.update.Type,
    ): InSpace<Option.Option<Category>>;
    /** Fails with `CategoryInUse` when a foreign key still points at the row. */
    remove(id: CategoryId): InSpace<void, CategoryInUse>;
  }
>()("bida/categories/CategoriesRepository") {
  static readonly layer = Layer.effect(
    CategoriesRepository,
    Effect.gen(function* () {
      const sql = yield* SqlClient.SqlClient;
      const columns = sql`id, name, color, icon, created_at, updated_at`;

      const listAll = SqlSchema.findAll({
        Request: Schema.String,
        Result: Category,
        execute: (spaceId) =>
          sql`SELECT ${columns} FROM categories WHERE space_id = ${spaceId}
            ORDER BY lower(name)`,
      });
      const findOne = SqlSchema.findOneOption({
        Request: Schema.Struct({ spaceId: Schema.String, id: Schema.String }),
        Result: Category,
        execute: ({ spaceId, id }) =>
          sql`SELECT ${columns} FROM categories
            WHERE id = ${id} AND space_id = ${spaceId}`,
      });
      const insertOne = SqlSchema.findOne({
        Request: Schema.Struct({
          spaceId: Schema.String,
          row: Category.insert,
        }),
        Result: Category,
        execute: ({ spaceId, row }) =>
          sql`INSERT INTO categories ${sql.insert({ ...row, spaceId })}
            RETURNING ${columns}`,
      });
      const updateOne = SqlSchema.findOneOption({
        Request: Schema.Struct({
          spaceId: Schema.String,
          row: Category.update,
        }),
        Result: Category,
        execute: ({ spaceId, row }) =>
          sql`UPDATE categories SET ${sql.update(row, ["id"])}
            WHERE id = ${row.id} AND space_id = ${spaceId} RETURNING ${columns}`,
      });
      const deleteOne = SqlSchema.void({
        Request: Schema.Struct({ spaceId: Schema.String, id: Schema.String }),
        execute: ({ spaceId, id }) =>
          sql`DELETE FROM categories WHERE id = ${id} AND space_id = ${spaceId}`,
      });

      const spaceId = Effect.gen(function* () {
        return (yield* CurrentSpace).id;
      });

      return CategoriesRepository.of({
        list: Effect.flatMap(spaceId, (id) => listAll(id)).pipe(
          Effect.orDie,
          Effect.withSpan("CategoriesRepository.list"),
        ),
        findById: (id) =>
          Effect.flatMap(spaceId, (spaceId) => findOne({ spaceId, id })).pipe(
            Effect.orDie,
          ),
        insert: (row) =>
          Effect.flatMap(spaceId, (spaceId) =>
            insertOne({ spaceId, row }),
          ).pipe(Effect.orDie),
        update: (row) =>
          Effect.flatMap(spaceId, (spaceId) =>
            updateOne({ spaceId, row }),
          ).pipe(Effect.orDie),
        remove: (id) =>
          Effect.flatMap(spaceId, (spaceId) => deleteOne({ spaceId, id })).pipe(
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
