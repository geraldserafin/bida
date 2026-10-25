import {
  Email,
  EnvelopeId,
  InvitationId,
  Name,
  Role,
  UserId,
} from "@bida/api-contract";
import { Context, Effect, Layer, type Option, Schema } from "effect";
import { SqlClient, SqlSchema } from "effect/sql";

export const InvitationRow = Schema.Struct({
  id: InvitationId,
  envelopeId: EnvelopeId,
  envelopeName: Name,
  email: Email,
  role: Role,
  status: Schema.Literals(["invited", "accepted"]),
  invitedByEmail: Schema.NullOr(Email),
  invitedByName: Schema.NullOr(Name),
  acceptedBy: Schema.NullOr(UserId),
  expiresAt: Schema.DateTimeUtcFromDate,
  createdAt: Schema.DateTimeUtcFromDate,
});
export type InvitationRow = typeof InvitationRow.Type;

type Final = "approved" | "declined" | "rejected" | "revoked";

/** SQL only: invitations to share an envelope. */
export class InvitationsRepository extends Context.Service<
  InvitationsRepository,
  {
    /** The open invitation of the address to the envelope, if any. */
    findOpen(
      envelopeId: string,
      email: string,
    ): Effect.Effect<Option.Option<InvitationRow>>;
    find(id: string): Effect.Effect<Option.Option<InvitationRow>>;
    insert(input: {
      readonly id: string;
      readonly envelopeId: string;
      readonly email: string;
      readonly role: string;
      readonly invitedBy: string;
      readonly days: number;
    }): Effect.Effect<void>;
    /** Sets the role and starts the validity over. */
    renew(id: string, role: string, days: number): Effect.Effect<void>;
    /** Invitations waiting for an answer or for approval. */
    countOpen(envelopeId: string): Effect.Effect<number>;
    countSentSince(userId: string, seconds: number): Effect.Effect<number>;
    forEnvelope(
      envelopeId: string,
    ): Effect.Effect<ReadonlyArray<InvitationRow>>;
    /** Those the address has not answered yet. */
    forEmail(email: string): Effect.Effect<ReadonlyArray<InvitationRow>>;
    /**
     * Moves an invitation on, when it is in one of the `from` states and has not
     * expired. `false` when it is not.
     */
    advance(
      id: string,
      from: ReadonlyArray<"invited" | "accepted">,
      to: Final | "accepted",
      acceptedBy?: string,
    ): Effect.Effect<boolean>;
  }
>()("bida/invitations/InvitationsRepository") {
  static readonly layer = Layer.effect(
    InvitationsRepository,
    Effect.gen(function* () {
      const sql = yield* SqlClient.SqlClient;
      const select = sql`
        SELECT i.id, i.envelope_id, e.name AS envelope_name, i.email, i.role, i.status,
          u.email AS invited_by_email, u.name AS invited_by_name,
          i.accepted_by, i.expires_at, i.created_at
        FROM invitations i
        JOIN envelopes e ON e.id = i.envelope_id
        LEFT JOIN users u ON u.id = i.invited_by`;

      const findOpen = SqlSchema.findOneOption({
        Request: Schema.Struct({
          envelopeId: Schema.String,
          email: Schema.String,
        }),
        Result: InvitationRow,
        execute: ({ envelopeId, email }) =>
          sql`${select} WHERE i.envelope_id = ${envelopeId} AND i.email = ${email}
            AND i.status IN ('invited', 'accepted')`,
      });
      const find = SqlSchema.findOneOption({
        Request: Schema.String,
        Result: InvitationRow,
        execute: (id) =>
          sql`${select} WHERE i.id = ${id} AND i.status IN ('invited', 'accepted')`,
      });
      const forEnvelope = SqlSchema.findAll({
        Request: Schema.String,
        Result: InvitationRow,
        execute: (envelopeId) =>
          sql`${select} WHERE i.envelope_id = ${envelopeId}
            AND i.status IN ('invited', 'accepted') AND i.expires_at > now()
            ORDER BY i.created_at, i.id`,
      });
      const forEmail = SqlSchema.findAll({
        Request: Schema.String,
        Result: InvitationRow,
        execute: (email) =>
          sql`${select} WHERE i.email = ${email} AND i.status = 'invited'
            AND i.expires_at > now() ORDER BY i.created_at, i.id`,
      });
      const total = (
        query: Effect.Effect<ReadonlyArray<{ total: number }>, unknown>,
      ) =>
        query.pipe(
          Effect.map((rows) => rows[0]?.total ?? 0),
          Effect.orDie,
        );

      return InvitationsRepository.of({
        findOpen: (envelopeId, email) =>
          findOpen({ envelopeId, email }).pipe(Effect.orDie),
        find: (id) => find(id).pipe(Effect.orDie),
        insert: ({ id, envelopeId, email, role, invitedBy, days }) =>
          sql`INSERT INTO invitations (id, envelope_id, email, role, status, invited_by, expires_at)
            VALUES (${id}, ${envelopeId}, ${email}, ${role}, 'invited', ${invitedBy},
              now() + make_interval(days => ${days}))`.pipe(
            Effect.asVoid,
            Effect.orDie,
          ),
        renew: (id, role, days) =>
          sql`UPDATE invitations
            SET role = ${role}, updated_at = now(),
                expires_at = now() + make_interval(days => ${days})
            WHERE id = ${id}`.pipe(Effect.asVoid, Effect.orDie),
        countOpen: (envelopeId) =>
          total(
            sql<{
              total: number;
            }>`SELECT count(*)::int AS total FROM invitations
              WHERE envelope_id = ${envelopeId} AND status IN ('invited', 'accepted')
                AND expires_at > now()`,
          ),
        countSentSince: (userId, seconds) =>
          total(
            sql<{
              total: number;
            }>`SELECT count(*)::int AS total FROM invitations
              WHERE invited_by = ${userId}
                AND created_at > now() - make_interval(secs => ${seconds})`,
          ),
        forEnvelope: (envelopeId) => forEnvelope(envelopeId).pipe(Effect.orDie),
        forEmail: (email) => forEmail(email).pipe(Effect.orDie),
        advance: (id, from, to, acceptedBy) =>
          sql`UPDATE invitations
            SET status = ${to}, updated_at = now(),
                accepted_by = COALESCE(${acceptedBy ?? null}, accepted_by)
            WHERE id = ${id} AND status IN ${sql.in(from)} AND expires_at > now()
            RETURNING id`.pipe(
            Effect.map((rows) => rows.length === 1),
            Effect.orDie,
          ),
      });
    }),
  );
}
