import { DEFAULT_SPACE_ID, Space, type SpaceId } from "@bida/api-contract";
import { Context, Effect, Layer, type Option, Schema } from "effect";
import { SqlClient, SqlSchema } from "effect/sql";

/** SQL only. Spaces are the tenants, so nothing here is scoped to a space. */
export class SpacesRepository extends Context.Service<
  SpacesRepository,
  {
    /** The spaces the user is a member of, the one they joined first first. */
    listForUser(userId: string): Effect.Effect<ReadonlyArray<Space>>;
    /** `None` when the space does not exist or the user is not in it. */
    findForUser(
      userId: string,
      id: SpaceId,
    ): Effect.Effect<Option.Option<Space>>;
    insert(input: typeof Space.insert.Type): Effect.Effect<Space>;
    /** `None` when the row does not exist. */
    update(
      id: SpaceId,
      changes: { readonly name: string; readonly defaultCurrency: string },
    ): Effect.Effect<Option.Option<Space>>;
    addMember(
      spaceId: SpaceId,
      userId: string,
      role: "owner" | "member",
    ): Effect.Effect<void>;
    /** Whether anyone is in the space that exists from the start. */
    defaultSpaceHasMembers: Effect.Effect<boolean>;
  }
>()("bida/spaces/SpacesRepository") {
  static readonly layer = Layer.effect(
    SpacesRepository,
    Effect.gen(function* () {
      const sql = yield* SqlClient.SqlClient;
      const columns = sql`id, name, default_currency, created_at, updated_at`;
      const memberColumns = sql`s.id, s.name, s.default_currency, s.created_at, s.updated_at`;

      const listForUser = SqlSchema.findAll({
        Request: Schema.String,
        Result: Space,
        execute: (userId) =>
          sql`SELECT ${memberColumns} FROM spaces s
            JOIN memberships m ON m.space_id = s.id
            WHERE m.user_id = ${userId}
            ORDER BY m.created_at, s.id`,
      });
      const findForUser = SqlSchema.findOneOption({
        Request: Schema.Struct({ userId: Schema.String, id: Schema.String }),
        Result: Space,
        execute: ({ userId, id }) =>
          sql`SELECT ${memberColumns} FROM spaces s
            JOIN memberships m ON m.space_id = s.id
            WHERE m.user_id = ${userId} AND s.id = ${id}`,
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
        listForUser: (userId) => listForUser(userId).pipe(Effect.orDie),
        findForUser: (userId, id) =>
          findForUser({ userId, id }).pipe(Effect.orDie),
        insert: (input) => insert(input).pipe(Effect.orDie),
        update: (id, changes) => update({ id, ...changes }).pipe(Effect.orDie),
        addMember: (spaceId, userId, role) =>
          sql`INSERT INTO memberships (space_id, user_id, role)
            VALUES (${spaceId}, ${userId}, ${role})`.pipe(
            Effect.asVoid,
            Effect.orDie,
          ),
        defaultSpaceHasMembers: sql<{ present: boolean }>`
          SELECT EXISTS (
            SELECT 1 FROM memberships WHERE space_id = ${DEFAULT_SPACE_ID}
          ) AS present`.pipe(
          Effect.map((rows) => rows[0]?.present === true),
          Effect.orDie,
        ),
      });
    }),
  );
}
