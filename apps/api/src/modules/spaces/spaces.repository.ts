import { Space, type SpaceId } from "@bida/api-contract";
import { Context, Effect, Layer, type Option, Schema } from "effect";
import { SqlClient, SqlSchema } from "effect/sql";

/** SQL only. Spaces are the tenants, so nothing here is scoped to a space. */
export class SpacesRepository extends Context.Service<
  SpacesRepository,
  {
    list: Effect.Effect<ReadonlyArray<Space>>;
    findById(id: SpaceId): Effect.Effect<Option.Option<Space>>;
    insert(input: typeof Space.insert.Type): Effect.Effect<Space>;
    /** `None` when the row does not exist. */
    update(
      id: SpaceId,
      changes: { readonly name: string; readonly defaultCurrency: string },
    ): Effect.Effect<Option.Option<Space>>;
  }
>()("bida/spaces/SpacesRepository") {
  static readonly layer = Layer.effect(
    SpacesRepository,
    Effect.gen(function* () {
      const sql = yield* SqlClient.SqlClient;
      const columns = sql`id, name, default_currency, created_at, updated_at`;

      const list = SqlSchema.findAll({
        Request: Schema.Void,
        Result: Space,
        execute: () =>
          sql`SELECT ${columns} FROM spaces ORDER BY created_at, id`,
      });
      const findById = SqlSchema.findOneOption({
        Request: Schema.String,
        Result: Space,
        execute: (id) => sql`SELECT ${columns} FROM spaces WHERE id = ${id}`,
      });
      const insert = SqlSchema.findOne({
        Request: Space.insert,
        Result: Space,
        execute: (request) =>
          sql`INSERT INTO spaces ${sql.insert(request)} RETURNING ${columns}`,
      });
      const update = SqlSchema.findOneOption({
        Request: Schema.Struct({
          id: Schema.String,
          name: Schema.String,
          defaultCurrency: Schema.String,
        }),
        Result: Space,
        execute: ({ id, name, defaultCurrency }) =>
          sql`UPDATE spaces SET name = ${name}, default_currency = ${defaultCurrency},
            updated_at = now() WHERE id = ${id} RETURNING ${columns}`,
      });

      return SpacesRepository.of({
        list: list().pipe(Effect.orDie),
        findById: (id) => findById(id).pipe(Effect.orDie),
        insert: (input) => insert(input).pipe(Effect.orDie),
        update: (id, changes) => update({ id, ...changes }).pipe(Effect.orDie),
      });
    }),
  );
}
