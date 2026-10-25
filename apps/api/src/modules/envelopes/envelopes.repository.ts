import {
  Allocation,
  type AllocationId,
  Envelope,
  type EnvelopeId,
} from "@bida/api-contract";
import { Context, Effect, Layer, Option, Schema } from "effect";
import { SqlClient, SqlSchema } from "effect/sql";

export type MemberRole = "owner" | "member";

/** What was put into and spent from an envelope (only its own, not its children's). */
export interface Totals {
  /** Everybody's allocations. */
  readonly allocated: number;
  /** The allocations of one user. */
  readonly allocatedByUser: number;
  readonly spent: number;
}

export interface AllocationFilter {
  readonly envelopeIds: ReadonlyArray<EnvelopeId>;
  readonly from?: string | undefined;
  readonly to?: string | undefined;
}

export interface AllocationChanges {
  readonly amountMinor: number;
  readonly madeOn: string;
  readonly note: string | null;
}

const Totals = Schema.Struct({
  allocated: Schema.Number,
  allocatedByUser: Schema.Number,
  spent: Schema.Number,
});

/** SQL only: no business rules, infrastructure failures are defects. */
export class EnvelopesRepository extends Context.Service<
  EnvelopesRepository,
  {
    /** The envelopes the user can see: the ones they are a member of and their children. */
    listFor(userId: string): Effect.Effect<ReadonlyArray<Envelope>>;
    /** `None` when the envelope does not exist or the user cannot see it. */
    findFor(
      userId: string,
      id: EnvelopeId,
    ): Effect.Effect<Option.Option<Envelope>>;
    /** The role of the user in the top-level envelope the envelope belongs to. */
    roleOf(
      userId: string,
      id: EnvelopeId,
    ): Effect.Effect<Option.Option<MemberRole>>;
    /** The ids of the sub-envelopes of a top-level envelope. */
    childIds(id: EnvelopeId): Effect.Effect<ReadonlyArray<EnvelopeId>>;
    insert(input: typeof Envelope.insert.Type): Effect.Effect<Envelope>;
    addMember(
      envelopeId: EnvelopeId,
      userId: string,
      role: MemberRole,
    ): Effect.Effect<void>;
    /** `None` when the row does not exist. */
    update(
      id: EnvelopeId,
      changes: {
        readonly name: string;
        readonly color: string;
        readonly icon: string | null;
      },
    ): Effect.Effect<Option.Option<Envelope>>;
    /** Takes the sub-envelopes, allocations and expenses with it. */
    remove(id: EnvelopeId): Effect.Effect<void>;

    /** Allocations and spending of the envelope itself. */
    totals(id: EnvelopeId, userId: string): Effect.Effect<Totals>;
    /** The same, added up over all the sub-envelopes of a top-level envelope. */
    childTotals(id: EnvelopeId, userId: string): Effect.Effect<Totals>;

    listAllocations(
      filter: AllocationFilter,
    ): Effect.Effect<ReadonlyArray<Allocation>>;
    insertAllocation(
      input: typeof Allocation.insert.Type,
    ): Effect.Effect<Allocation>;
    /** The allocation, only when it is the user's own. */
    findOwnAllocation(
      userId: string,
      id: AllocationId,
    ): Effect.Effect<Option.Option<Allocation>>;
    updateAllocation(
      id: AllocationId,
      changes: AllocationChanges,
    ): Effect.Effect<Option.Option<Allocation>>;
    removeAllocation(id: AllocationId): Effect.Effect<void>;
    /** Serialises changes to the money of one top-level envelope, until the transaction ends. */
    lock(id: EnvelopeId): Effect.Effect<void>;
  }
>()("bida/envelopes/EnvelopesRepository") {
  static readonly layer = Layer.effect(
    EnvelopesRepository,
    Effect.gen(function* () {
      const sql = yield* SqlClient.SqlClient;

      const columns = sql`id, owner_id, parent_id, name, color, icon, created_at, updated_at`;
      const eColumns = sql`e.id, e.owner_id, e.parent_id, e.name, e.color, e.icon, e.created_at, e.updated_at`;
      // bigint comes back from pg as a string and `date` as a Date: cast both
      const allocationColumns = sql`id, envelope_id, user_id,
        amount_minor::float8 AS amount_minor, made_on::text AS made_on, note,
        created_at, updated_at`;

      const listFor = SqlSchema.findAll({
        Request: Schema.String,
        Result: Envelope,
        execute: (userId) =>
          sql`SELECT ${eColumns} FROM envelopes e
            JOIN envelope_members m
              ON m.envelope_id = COALESCE(e.parent_id, e.id) AND m.user_id = ${userId}
            ORDER BY lower(e.name), e.id`,
      });
      const findFor = SqlSchema.findOneOption({
        Request: Schema.Struct({ userId: Schema.String, id: Schema.String }),
        Result: Envelope,
        execute: ({ userId, id }) =>
          sql`SELECT ${eColumns} FROM envelopes e
            JOIN envelope_members m
              ON m.envelope_id = COALESCE(e.parent_id, e.id) AND m.user_id = ${userId}
            WHERE e.id = ${id}`,
      });
      const roleOf = SqlSchema.findOneOption({
        Request: Schema.Struct({ userId: Schema.String, id: Schema.String }),
        Result: Schema.Struct({ role: Schema.Literals(["owner", "member"]) }),
        execute: ({ userId, id }) =>
          sql`SELECT m.role FROM envelopes e
            JOIN envelope_members m
              ON m.envelope_id = COALESCE(e.parent_id, e.id) AND m.user_id = ${userId}
            WHERE e.id = ${id}`,
      });
      const childIds = SqlSchema.findAll({
        Request: Schema.String,
        Result: Schema.Struct({ id: Schema.String }),
        execute: (id) => sql`SELECT id FROM envelopes WHERE parent_id = ${id}`,
      });
      const insert = SqlSchema.findOne({
        Request: Envelope.insert,
        Result: Envelope,
        execute: (request) =>
          sql`INSERT INTO envelopes ${sql.insert(request)} RETURNING ${columns}`,
      });
      const update = SqlSchema.findOneOption({
        Request: Schema.Struct({
          id: Schema.String,
          name: Schema.String,
          color: Schema.String,
          icon: Schema.NullOr(Schema.String),
        }),
        Result: Envelope,
        execute: ({ id, name, color, icon }) =>
          sql`UPDATE envelopes SET name = ${name}, color = ${color},
            icon = ${icon}, updated_at = now()
            WHERE id = ${id} RETURNING ${columns}`,
      });

      const totals = SqlSchema.findOne({
        Request: Schema.Struct({ id: Schema.String, userId: Schema.String }),
        Result: Totals,
        execute: ({ id, userId }) =>
          sql`SELECT
              (SELECT COALESCE(SUM(amount_minor), 0)::float8 FROM allocations
                WHERE envelope_id = ${id}) AS allocated,
              (SELECT COALESCE(SUM(amount_minor), 0)::float8 FROM allocations
                WHERE envelope_id = ${id} AND user_id = ${userId}) AS allocated_by_user,
              (SELECT COALESCE(SUM(amount_minor), 0)::float8 FROM expenses
                WHERE envelope_id = ${id}) AS spent`,
      });
      const childTotals = SqlSchema.findOne({
        Request: Schema.Struct({ id: Schema.String, userId: Schema.String }),
        Result: Totals,
        execute: ({ id, userId }) =>
          sql`SELECT
              (SELECT COALESCE(SUM(a.amount_minor), 0)::float8 FROM allocations a
                JOIN envelopes c ON c.id = a.envelope_id
                WHERE c.parent_id = ${id}) AS allocated,
              (SELECT COALESCE(SUM(a.amount_minor), 0)::float8 FROM allocations a
                JOIN envelopes c ON c.id = a.envelope_id
                WHERE c.parent_id = ${id} AND a.user_id = ${userId}) AS allocated_by_user,
              (SELECT COALESCE(SUM(x.amount_minor), 0)::float8 FROM expenses x
                JOIN envelopes c ON c.id = x.envelope_id
                WHERE c.parent_id = ${id}) AS spent`,
      });

      const listAllocations = SqlSchema.findAll({
        Request: Schema.Struct({
          envelopeIds: Schema.Array(Schema.String),
          from: Schema.optional(Schema.String),
          to: Schema.optional(Schema.String),
        }),
        Result: Allocation,
        execute: ({ envelopeIds, from, to }) => {
          // sql.in with an empty list would be invalid SQL
          const conditions =
            envelopeIds.length === 0
              ? [sql`FALSE`]
              : [sql`${sql.in("envelope_id", envelopeIds)}`];
          if (from !== undefined) conditions.push(sql`made_on >= ${from}`);
          if (to !== undefined) conditions.push(sql`made_on <= ${to}`);
          return sql`SELECT ${allocationColumns} FROM allocations
            WHERE ${sql.and(conditions)}
            ORDER BY made_on DESC, created_at DESC, id DESC`;
        },
      });
      const insertAllocation = SqlSchema.findOne({
        Request: Allocation.insert,
        Result: Allocation,
        execute: (request) =>
          sql`INSERT INTO allocations ${sql.insert(request)}
            RETURNING ${allocationColumns}`,
      });
      const findOwnAllocation = SqlSchema.findOneOption({
        Request: Schema.Struct({ userId: Schema.String, id: Schema.String }),
        Result: Allocation,
        execute: ({ userId, id }) =>
          sql`SELECT ${allocationColumns} FROM allocations
            WHERE id = ${id} AND user_id = ${userId}`,
      });
      const updateAllocation = SqlSchema.findOneOption({
        Request: Schema.Struct({
          id: Schema.String,
          amountMinor: Schema.Int,
          madeOn: Schema.String,
          note: Schema.NullOr(Schema.String),
        }),
        Result: Allocation,
        execute: ({ id, amountMinor, madeOn, note }) =>
          sql`UPDATE allocations SET amount_minor = ${amountMinor},
            made_on = ${madeOn}, note = ${note}, updated_at = now()
            WHERE id = ${id} RETURNING ${allocationColumns}`,
      });

      return EnvelopesRepository.of({
        listFor: (userId) => listFor(userId).pipe(Effect.orDie),
        findFor: (userId, id) => findFor({ userId, id }).pipe(Effect.orDie),
        roleOf: (userId, id) =>
          roleOf({ userId, id }).pipe(
            Effect.map(Option.map((found) => found.role)),
            Effect.orDie,
          ),
        childIds: (id) =>
          childIds(id).pipe(
            Effect.map((rows) => rows.map((row) => row.id as EnvelopeId)),
            Effect.orDie,
          ),
        insert: (input) => insert(input).pipe(Effect.orDie),
        addMember: (envelopeId, userId, role) =>
          sql`INSERT INTO envelope_members (envelope_id, user_id, role)
            VALUES (${envelopeId}, ${userId}, ${role})`.pipe(
            Effect.asVoid,
            Effect.orDie,
          ),
        update: (id, changes) => update({ id, ...changes }).pipe(Effect.orDie),
        remove: (id) =>
          sql`DELETE FROM envelopes WHERE id = ${id}`.pipe(
            Effect.asVoid,
            Effect.orDie,
          ),
        totals: (id, userId) => totals({ id, userId }).pipe(Effect.orDie),
        childTotals: (id, userId) =>
          childTotals({ id, userId }).pipe(Effect.orDie),
        listAllocations: (filter) => listAllocations(filter).pipe(Effect.orDie),
        insertAllocation: (input) => insertAllocation(input).pipe(Effect.orDie),
        findOwnAllocation: (userId, id) =>
          findOwnAllocation({ userId, id }).pipe(Effect.orDie),
        updateAllocation: (id, changes) =>
          updateAllocation({ id, ...changes }).pipe(Effect.orDie),
        removeAllocation: (id) =>
          sql`DELETE FROM allocations WHERE id = ${id}`.pipe(
            Effect.asVoid,
            Effect.orDie,
          ),
        lock: (id) =>
          sql`SELECT pg_advisory_xact_lock(hashtext(${id}))`.pipe(
            Effect.asVoid,
            Effect.orDie,
          ),
      });
    }),
  );
}
