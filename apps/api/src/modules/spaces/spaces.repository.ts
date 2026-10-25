import {
  DEFAULT_SPACE_ID,
  Email,
  Name,
  Role,
  Space,
  type SpaceId,
  UserId,
} from "@bida/api-contract";
import { Context, Effect, Layer, Option, Schema } from "effect";
import { SqlClient, SqlSchema } from "effect/sql";

/** A space with what the asking user is in it. */
export interface Membership {
  readonly space: Space;
  readonly role: Role;
  readonly memberCount: number;
}

/** A member as the database holds them (the contract's has `Member`). */
export const MemberRow = Schema.Struct({
  userId: UserId,
  email: Email,
  name: Schema.NullOr(Name),
  role: Role,
  joinedAt: Schema.DateTimeUtcFromDate,
});
export type MemberRow = typeof MemberRow.Type;

const SpaceWithRole = Schema.Struct({
  id: Schema.String,
  role: Role,
  memberCount: Schema.Int,
});

/** SQL only. Spaces are the tenants, so nothing here is scoped to a space. */
export class SpacesRepository extends Context.Service<
  SpacesRepository,
  {
    /** The user's spaces: the personal one first, then by when they joined. */
    listForUser(userId: string): Effect.Effect<ReadonlyArray<Membership>>;
    /** `None` when the space does not exist or the user is not in it. */
    findForUser(
      userId: string,
      id: SpaceId,
    ): Effect.Effect<Option.Option<Membership>>;
    /** A personal space is for one user, who is passed as `personalFor`. */
    insert(
      input: typeof Space.insert.Type,
      personalFor?: string,
    ): Effect.Effect<Space>;
    /** `None` when the row does not exist. */
    update(
      id: SpaceId,
      changes: { readonly name: string; readonly defaultCurrency: string },
    ): Effect.Effect<Option.Option<Space>>;
    delete(id: SpaceId): Effect.Effect<void>;
    /** Holds the space's row until the transaction ends, to serialize changes. */
    lock(id: SpaceId): Effect.Effect<void>;

    addMember(
      spaceId: SpaceId,
      userId: string,
      role: Role,
    ): Effect.Effect<void>;
    members(spaceId: SpaceId): Effect.Effect<ReadonlyArray<MemberRow>>;
    findMember(
      spaceId: SpaceId,
      userId: string,
    ): Effect.Effect<Option.Option<MemberRow>>;
    setRole(
      spaceId: SpaceId,
      userId: string,
      role: Role,
    ): Effect.Effect<Option.Option<MemberRow>>;
    /** `false` when the user was not a member. */
    removeMember(spaceId: SpaceId, userId: string): Effect.Effect<boolean>;
    countOwners(spaceId: SpaceId): Effect.Effect<number>;
    countMembers(spaceId: SpaceId): Effect.Effect<number>;
    /** Spaces the user is in, personal one included. */
    countSpacesOf(userId: string): Effect.Effect<number>;

    /** Whether anyone is in the space that exists from the start. */
    defaultSpaceHasMembers: Effect.Effect<boolean>;
    /** Makes the space from before accounts the user's personal one. */
    giveDefaultTo(userId: string): Effect.Effect<void>;
  }
>()("bida/spaces/SpacesRepository") {
  static readonly layer = Layer.effect(
    SpacesRepository,
    Effect.gen(function* () {
      const sql = yield* SqlClient.SqlClient;
      const columns = sql`id, name, default_currency, kind, created_at, updated_at`;
      const spaceColumns = sql`s.id, s.name, s.default_currency, s.kind, s.created_at, s.updated_at`;
      const memberColumns = sql`u.id AS user_id, u.email, u.name, m.role, m.created_at AS joined_at`;

      const spacesOf = SqlSchema.findAll({
        Request: Schema.String,
        Result: Space,
        execute: (userId) =>
          sql`SELECT ${spaceColumns} FROM spaces s
            JOIN memberships m ON m.space_id = s.id
            WHERE m.user_id = ${userId}
            ORDER BY (s.kind <> 'personal'), m.created_at, s.id`,
      });
      const rolesOf = SqlSchema.findAll({
        Request: Schema.String,
        Result: SpaceWithRole,
        execute: (userId) =>
          sql`SELECT m.space_id AS id, m.role,
              (SELECT count(*)::int FROM memberships c WHERE c.space_id = m.space_id)
                AS member_count
            FROM memberships m WHERE m.user_id = ${userId}`,
      });
      const insert = SqlSchema.findOne({
        Request: Schema.Struct({
          space: Space.insert,
          personalFor: Schema.NullOr(Schema.String),
        }),
        Result: Space,
        execute: ({ space, personalFor }) =>
          sql`INSERT INTO spaces ${sql.insert({ ...space, personalFor })}
            RETURNING ${columns}`,
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
      const members = SqlSchema.findAll({
        Request: Schema.String,
        Result: MemberRow,
        execute: (spaceId) =>
          sql`SELECT ${memberColumns} FROM memberships m
            JOIN users u ON u.id = m.user_id
            WHERE m.space_id = ${spaceId}
            ORDER BY m.created_at, u.id`,
      });
      const findMember = SqlSchema.findOneOption({
        Request: Schema.Struct({
          spaceId: Schema.String,
          userId: Schema.String,
        }),
        Result: MemberRow,
        execute: ({ spaceId, userId }) =>
          sql`SELECT ${memberColumns} FROM memberships m
            JOIN users u ON u.id = m.user_id
            WHERE m.space_id = ${spaceId} AND m.user_id = ${userId}`,
      });
      const setRole = SqlSchema.findOneOption({
        Request: Schema.Struct({
          spaceId: Schema.String,
          userId: Schema.String,
          role: Schema.String,
        }),
        Result: MemberRow,
        execute: ({ spaceId, userId, role }) =>
          sql`WITH changed AS (
              UPDATE memberships SET role = ${role}
              WHERE space_id = ${spaceId} AND user_id = ${userId}
              RETURNING space_id, user_id, role, created_at
            )
            SELECT u.id AS user_id, u.email, u.name, m.role, m.created_at AS joined_at
            FROM changed m JOIN users u ON u.id = m.user_id`,
      });

      const count = (
        query: Effect.Effect<ReadonlyArray<{ total: number }>, unknown>,
      ) =>
        query.pipe(
          Effect.map((rows) => rows[0]?.total ?? 0),
          Effect.orDie,
        );

      return SpacesRepository.of({
        listForUser: (userId) =>
          Effect.all([spacesOf(userId), rolesOf(userId)]).pipe(
            Effect.map(([spaces, roles]) =>
              spaces.flatMap((space) => {
                const mine = roles.find((r) => r.id === space.id);
                return mine
                  ? [{ space, role: mine.role, memberCount: mine.memberCount }]
                  : [];
              }),
            ),
            Effect.orDie,
          ),
        findForUser: (userId, id) =>
          Effect.all([spacesOf(userId), rolesOf(userId)]).pipe(
            Effect.map(([spaces, roles]) => {
              const space = spaces.find((s) => s.id === id);
              const mine = roles.find((r) => r.id === id);
              return space && mine
                ? Option.some({
                    space,
                    role: mine.role,
                    memberCount: mine.memberCount,
                  })
                : Option.none();
            }),
            Effect.orDie,
          ),
        insert: (input, personalFor) =>
          insert({ space: input, personalFor: personalFor ?? null }).pipe(
            Effect.orDie,
          ),
        update: (id, changes) => update({ id, ...changes }).pipe(Effect.orDie),
        delete: (id) =>
          sql`DELETE FROM spaces WHERE id = ${id}`.pipe(
            Effect.asVoid,
            Effect.orDie,
          ),
        lock: (id) =>
          sql`SELECT 1 FROM spaces WHERE id = ${id} FOR UPDATE`.pipe(
            Effect.asVoid,
            Effect.orDie,
          ),

        addMember: (spaceId, userId, role) =>
          sql`INSERT INTO memberships (space_id, user_id, role)
            VALUES (${spaceId}, ${userId}, ${role})`.pipe(
            Effect.asVoid,
            Effect.orDie,
          ),
        members: (spaceId) => members(spaceId).pipe(Effect.orDie),
        findMember: (spaceId, userId) =>
          findMember({ spaceId, userId }).pipe(Effect.orDie),
        setRole: (spaceId, userId, role) =>
          setRole({ spaceId, userId, role }).pipe(Effect.orDie),
        removeMember: (spaceId, userId) =>
          sql`DELETE FROM memberships
            WHERE space_id = ${spaceId} AND user_id = ${userId} RETURNING user_id`.pipe(
            Effect.map((rows) => rows.length === 1),
            Effect.orDie,
          ),
        countOwners: (spaceId) =>
          count(
            sql<{
              total: number;
            }>`SELECT count(*)::int AS total FROM memberships
              WHERE space_id = ${spaceId} AND role = 'owner'`,
          ),
        countMembers: (spaceId) =>
          count(
            sql<{
              total: number;
            }>`SELECT count(*)::int AS total FROM memberships
              WHERE space_id = ${spaceId}`,
          ),
        countSpacesOf: (userId) =>
          count(
            sql<{
              total: number;
            }>`SELECT count(*)::int AS total FROM memberships
              WHERE user_id = ${userId}`,
          ),

        defaultSpaceHasMembers: sql<{ present: boolean }>`
          SELECT EXISTS (
            SELECT 1 FROM memberships WHERE space_id = ${DEFAULT_SPACE_ID}
          ) AS present`.pipe(
          Effect.map((rows) => rows[0]?.present === true),
          Effect.orDie,
        ),
        giveDefaultTo: (userId) =>
          Effect.all([
            sql`UPDATE spaces SET kind = 'personal', personal_for = ${userId}
              WHERE id = ${DEFAULT_SPACE_ID}`,
            sql`INSERT INTO memberships (space_id, user_id, role)
              VALUES (${DEFAULT_SPACE_ID}, ${userId}, 'owner')`,
          ]).pipe(Effect.asVoid, Effect.orDie),
      });
    }),
  );
}
