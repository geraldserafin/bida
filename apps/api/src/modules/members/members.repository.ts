import {
  type Contribution,
  Email,
  type EnvelopeId,
  type Member,
  Name,
  Role,
  UserId,
} from "@bida/api-contract";
import { Context, Effect, Layer, Schema } from "effect";
import { SqlClient, SqlSchema } from "effect/sql";

const MemberRow = Schema.Struct({
  userId: UserId,
  email: Email,
  name: Schema.NullOr(Name),
  role: Role,
  joinedAt: Schema.DateTimeUtcFromDate,
});
export type MemberRow = typeof MemberRow.Type;

const ContributionRow = Schema.Struct({
  envelopeId: Schema.String,
  userId: UserId,
  amountMinor: Schema.Number,
});

/** SQL only: who shares an envelope and what they put into it. */
export class MembersRepository extends Context.Service<
  MembersRepository,
  {
    /** The members of a top-level envelope, the one who joined first first. */
    list(envelopeId: EnvelopeId): Effect.Effect<ReadonlyArray<MemberRow>>;
    insert(
      envelopeId: EnvelopeId,
      userId: string,
      role: Role,
    ): Effect.Effect<void>;
    setRole(
      envelopeId: EnvelopeId,
      userId: string,
      role: Role,
    ): Effect.Effect<void>;
    /**
     * Takes the member out. Their recurring rules on the envelope and its
     * sub-envelopes go too, since they cannot see them any more.
     */
    remove(envelopeId: EnvelopeId, userId: string): Effect.Effect<void>;
    /** Net amount per member and per envelope of the tree, all time. */
    contributions(
      envelopeId: EnvelopeId,
    ): Effect.Effect<ReadonlyArray<Contribution>>;
    /** Serialises changes to the members of one envelope until the transaction ends. */
    lock(envelopeId: EnvelopeId): Effect.Effect<void>;
  }
>()("bida/members/MembersRepository") {
  static readonly layer = Layer.effect(
    MembersRepository,
    Effect.gen(function* () {
      const sql = yield* SqlClient.SqlClient;

      const list = SqlSchema.findAll({
        Request: Schema.String,
        Result: MemberRow,
        execute: (envelopeId) =>
          sql`SELECT m.user_id, u.email, u.name, m.role, m.created_at AS joined_at
            FROM envelope_members m JOIN users u ON u.id = m.user_id
            WHERE m.envelope_id = ${envelopeId}
            ORDER BY m.created_at, u.email`,
      });
      const contributions = SqlSchema.findAll({
        Request: Schema.String,
        Result: ContributionRow,
        execute: (envelopeId) =>
          sql`SELECT a.envelope_id, a.user_id, SUM(a.amount_minor)::float8 AS amount_minor
            FROM allocations a JOIN envelopes e ON e.id = a.envelope_id
            WHERE e.id = ${envelopeId} OR e.parent_id = ${envelopeId}
            GROUP BY a.envelope_id, a.user_id
            ORDER BY (a.envelope_id = ${envelopeId}) DESC, a.envelope_id, a.user_id`,
      });

      return MembersRepository.of({
        list: (envelopeId) => list(envelopeId).pipe(Effect.orDie),
        insert: (envelopeId, userId, role) =>
          sql`INSERT INTO envelope_members (envelope_id, user_id, role)
            VALUES (${envelopeId}, ${userId}, ${role})`.pipe(
            Effect.asVoid,
            Effect.orDie,
          ),
        setRole: (envelopeId, userId, role) =>
          sql`UPDATE envelope_members SET role = ${role}
            WHERE envelope_id = ${envelopeId} AND user_id = ${userId}`.pipe(
            Effect.asVoid,
            Effect.orDie,
          ),
        remove: (envelopeId, userId) =>
          Effect.gen(function* () {
            // the rules live in another module's table; they only make sense
            // for somebody who can see the envelope
            yield* sql`DELETE FROM recurring_rules
              WHERE user_id = ${userId}
                AND envelope_id IN (
                  SELECT id FROM envelopes
                  WHERE id = ${envelopeId} OR parent_id = ${envelopeId})`;
            yield* sql`DELETE FROM envelope_members
              WHERE envelope_id = ${envelopeId} AND user_id = ${userId}`;
          }).pipe(Effect.orDie),
        contributions: (envelopeId) =>
          contributions(envelopeId).pipe(
            Effect.map((rows) =>
              rows.map(
                (row): Contribution => ({
                  envelopeId: row.envelopeId as EnvelopeId,
                  userId: row.userId,
                  amountMinor: row.amountMinor,
                }),
              ),
            ),
            Effect.orDie,
          ),
        lock: (envelopeId) =>
          sql`SELECT pg_advisory_xact_lock(hashtext(${`members/${envelopeId}`}))`.pipe(
            Effect.asVoid,
            Effect.orDie,
          ),
      });
    }),
  );
}

export const toMember = (row: MemberRow): Member => row;
