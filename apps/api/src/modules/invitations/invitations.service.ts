import {
  AlreadyMember,
  type EnvelopeId,
  type EnvelopeNotFound,
  Forbidden,
  INVITATION_DAYS,
  type Invitation,
  type InvitationId,
  InvitationNotFound,
  LimitReached,
  MAX_INVITATIONS_PER_HOUR,
  MAX_MEMBERS_PER_ENVELOPE,
  type Member,
  NotShareable,
  type Role,
  type UserId,
} from "@bida/api-contract";
import { Context, DateTime, Effect, Layer, Option } from "effect";
import { SqlClient } from "effect/sql";
import { AppConfig } from "../../platform/config.ts";
import { Mailer } from "../../platform/mailer.ts";
import { EnvelopesService } from "../envelopes/envelopes.module.ts";
import { MembersService } from "../members/members.module.ts";
import {
  type InvitationRow,
  InvitationsRepository,
} from "./invitations.repository.ts";

const normalize = (email: string) => email.trim().toLowerCase();

const present = (row: InvitationRow): Invitation => ({
  id: row.id,
  envelopeId: row.envelopeId,
  envelopeName: row.envelopeName,
  email: row.email,
  role: row.role,
  status: row.status,
  invitedBy:
    row.invitedByEmail === null
      ? null
      : { email: row.invitedByEmail, name: row.invitedByName },
  acceptedBy: row.acceptedBy,
  expiresAt: row.expiresAt,
  createdAt: row.createdAt,
});

const who = (name: string | null, email: string) => name ?? email;

/** Inviting people to share an envelope, and letting them in. */
export class InvitationsService extends Context.Service<
  InvitationsService,
  {
    invite(
      userId: UserId,
      envelopeId: EnvelopeId,
      email: string,
      role: Role,
    ): Effect.Effect<
      Invitation,
      EnvelopeNotFound | Forbidden | NotShareable | AlreadyMember | LimitReached
    >;
    forEnvelope(
      userId: UserId,
      envelopeId: EnvelopeId,
    ): Effect.Effect<
      ReadonlyArray<Invitation>,
      EnvelopeNotFound | Forbidden | NotShareable
    >;
    revoke(
      userId: UserId,
      envelopeId: EnvelopeId,
      id: InvitationId,
    ): Effect.Effect<
      void,
      EnvelopeNotFound | Forbidden | NotShareable | InvitationNotFound
    >;
    approve(
      userId: UserId,
      envelopeId: EnvelopeId,
      id: InvitationId,
    ): Effect.Effect<
      Member,
      | EnvelopeNotFound
      | Forbidden
      | NotShareable
      | InvitationNotFound
      | LimitReached
    >;
    /** The open invitations for the address of a signed-in user. */
    mine(email: string): Effect.Effect<ReadonlyArray<Invitation>>;
    accept(
      userId: UserId,
      email: string,
      id: InvitationId,
    ): Effect.Effect<Invitation, InvitationNotFound>;
    decline(
      email: string,
      id: InvitationId,
    ): Effect.Effect<void, InvitationNotFound>;
  }
>()("bida/invitations/InvitationsService") {
  static readonly layer = Layer.effect(
    InvitationsService,
    Effect.gen(function* () {
      const repo = yield* InvitationsRepository;
      const envelopes = yield* EnvelopesService;
      const members = yield* MembersService;
      const mailer = yield* Mailer;
      const sql = yield* SqlClient.SqlClient;
      const { appUrl } = yield* AppConfig;
      const app = appUrl.replace(/\/$/, "");

      /**
       * The top-level envelope of an owner; `Forbidden` for a member, not found
       * for others, `NotShareable` for a sub-envelope.
       */
      const ownedBy = Effect.fn("InvitationsService.ownedBy")(function* (
        userId: UserId,
        envelopeId: EnvelopeId,
      ) {
        const { envelope, role } = yield* envelopes.access(userId, envelopeId);
        if (role !== "owner") return yield* new Forbidden();
        if (envelope.parentId !== null) return yield* new NotShareable();
        return envelope;
      });

      /** An invitation of the envelope that is still open, or not found. */
      const openOf = Effect.fn("InvitationsService.openOf")(function* (
        envelopeId: EnvelopeId,
        id: InvitationId,
      ) {
        const row = yield* repo.find(id);
        if (
          Option.isNone(row) ||
          row.value.envelopeId !== envelopeId ||
          DateTime.toEpochMillis(row.value.expiresAt) <= Date.now()
        )
          return yield* new InvitationNotFound({ id });
        return row.value;
      });

      const invite = Effect.fn("InvitationsService.invite")(function* (
        userId: UserId,
        envelopeId: EnvelopeId,
        rawEmail: string,
        role: Role,
      ) {
        const envelope = yield* ownedBy(userId, envelopeId);
        const email = normalize(rawEmail);

        const current = yield* members.membersOf(envelope.id);
        if (current.some((m) => m.email === email))
          return yield* new AlreadyMember();

        const existing = yield* repo.findOpen(envelope.id, email);
        const open = yield* repo.countOpen(envelope.id);
        // renewing an open invitation does not take another place
        if (
          Option.isNone(existing) &&
          current.length + open >= MAX_MEMBERS_PER_ENVELOPE
        )
          return yield* new LimitReached({ limit: MAX_MEMBERS_PER_ENVELOPE });
        if (
          (yield* repo.countSentSince(userId, 3600)) >= MAX_INVITATIONS_PER_HOUR
        )
          return yield* new LimitReached({ limit: MAX_INVITATIONS_PER_HOUR });

        if (Option.isSome(existing)) {
          yield* repo.renew(existing.value.id, role, INVITATION_DAYS);
        } else {
          yield* repo.insert({
            id: crypto.randomUUID(),
            envelopeId: envelope.id,
            email,
            role,
            invitedBy: userId,
            days: INVITATION_DAYS,
          });
        }
        const saved = yield* repo.findOpen(envelope.id, email);
        const row = yield* Option.match(saved, {
          onNone: () => Effect.die("invitation vanished"),
          onSome: Effect.succeed,
        });
        const inviter = current.find((m) => m.userId === userId);
        yield* mailer.send({
          to: email,
          subject: `Zaproszenie do wspólnej koperty „${envelope.name}"`,
          text: `${who(inviter?.name ?? null, inviter?.email ?? "Ktoś")} zaprasza Cię do wspólnej koperty „${envelope.name}" w PLNing.\n\nZaloguj się tym adresem e-mail (${email}) pod adresem ${app}, a zaproszenie zobaczysz po zalogowaniu. Zaproszenie jest ważne ${INVITATION_DAYS} dni. Jeśli go nie oczekujesz, zignoruj tę wiadomość.`,
        });
        return present(row);
      });

      const forEnvelope = Effect.fn("InvitationsService.forEnvelope")(
        function* (userId: UserId, envelopeId: EnvelopeId) {
          const envelope = yield* ownedBy(userId, envelopeId);
          return (yield* repo.forEnvelope(envelope.id)).map(present);
        },
      );

      const revoke = Effect.fn("InvitationsService.revoke")(function* (
        userId: UserId,
        envelopeId: EnvelopeId,
        id: InvitationId,
      ) {
        const envelope = yield* ownedBy(userId, envelopeId);
        const row = yield* openOf(envelope.id, id);
        const ended = yield* repo.advance(
          id,
          ["invited", "accepted"],
          row.status === "accepted" ? "rejected" : "revoked",
        );
        if (!ended) return yield* new InvitationNotFound({ id });
      });

      const approve = Effect.fn("InvitationsService.approve")(function* (
        userId: UserId,
        envelopeId: EnvelopeId,
        id: InvitationId,
      ) {
        const envelope = yield* ownedBy(userId, envelopeId);
        const row = yield* openOf(envelope.id, id);
        if (row.status !== "accepted" || row.acceptedBy === null)
          return yield* new InvitationNotFound({ id });
        const person = row.acceptedBy;
        const member = yield* sql
          .withTransaction(
            Effect.gen(function* () {
              // approved twice at once: the person is in already
              const added = yield* members.add(envelope.id, person, row.role);
              yield* repo.advance(id, ["accepted"], "approved");
              return added;
            }),
          )
          .pipe(Effect.catchTag("SqlError", (error) => Effect.die(error)));
        yield* mailer.send({
          to: row.email,
          subject: `Dołączyłeś do wspólnej koperty „${row.envelopeName}"`,
          text: `Właściciel zatwierdził Twoje dołączenie do wspólnej koperty „${row.envelopeName}". Otwórz PLNing (${app}) i znajdziesz ją na liście kopert.`,
        });
        return member;
      });

      const mine = Effect.fn("InvitationsService.mine")(function* (
        email: string,
      ) {
        return (yield* repo.forEmail(normalize(email))).map(present);
      });

      /** An invitation for the address of the user, still waiting for an answer. */
      const mineToAnswer = Effect.fn("InvitationsService.mineToAnswer")(
        function* (email: string, id: InvitationId) {
          const row = yield* repo.find(id);
          if (
            Option.isNone(row) ||
            row.value.email !== normalize(email) ||
            row.value.status !== "invited"
          )
            return yield* new InvitationNotFound({ id });
          return row.value;
        },
      );

      const accept = Effect.fn("InvitationsService.accept")(function* (
        userId: UserId,
        email: string,
        id: InvitationId,
      ) {
        const row = yield* mineToAnswer(email, id);
        if (!(yield* repo.advance(id, ["invited"], "accepted", userId)))
          return yield* new InvitationNotFound({ id });
        const owners = yield* members.ownersOf(row.envelopeId);
        yield* Effect.forEach(owners, (owner) =>
          mailer.send({
            to: owner.email,
            subject: `${row.email} chce dołączyć do „${row.envelopeName}"`,
            text: `${row.email} przyjął zaproszenie do wspólnej koperty „${row.envelopeName}". Otwórz PLNing (${app}) i zatwierdź to w członkach koperty, żeby osoba dostała dostęp. Jeśli nie znasz tego adresu, odrzuć zaproszenie.`,
          }),
        );
        const updated = yield* repo.find(id);
        return yield* Option.match(updated, {
          onNone: () => Effect.fail(new InvitationNotFound({ id })),
          onSome: (r) => Effect.succeed(present(r)),
        });
      });

      const decline = Effect.fn("InvitationsService.decline")(function* (
        email: string,
        id: InvitationId,
      ) {
        yield* mineToAnswer(email, id);
        yield* repo.advance(id, ["invited"], "declined");
      });

      return InvitationsService.of({
        invite,
        forEnvelope,
        revoke,
        approve,
        mine,
        accept,
        decline,
      });
    }),
  );
}
