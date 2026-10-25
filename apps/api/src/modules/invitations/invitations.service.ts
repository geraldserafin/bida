import {
  AlreadyMember,
  Forbidden,
  INVITATION_DAYS,
  type Invitation,
  type InvitationId,
  InvitationNotFound,
  LimitReached,
  MAX_INVITATIONS_PER_HOUR,
  MAX_MEMBERS_PER_SPACE,
  type Member,
  PersonalSpace,
  type Role,
  type SpaceId,
  SpaceNotFound,
} from "@bida/api-contract";
import { Context, DateTime, Effect, Layer, Option } from "effect";
import { SqlClient } from "effect/sql";
import { AppConfig } from "../../platform/config.ts";
import { Mailer } from "../../platform/mailer.ts";
import { SpacesService } from "../spaces/spaces.module.ts";
import {
  type InvitationRow,
  InvitationsRepository,
} from "./invitations.repository.ts";

const normalize = (email: string) => email.trim().toLowerCase();

const present = (row: InvitationRow): Invitation => ({
  id: row.id,
  spaceId: row.spaceId,
  spaceName: row.spaceName,
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

/** Inviting people to shared spaces, and letting them in. */
export class InvitationsService extends Context.Service<
  InvitationsService,
  {
    invite(
      userId: string,
      spaceId: SpaceId,
      email: string,
      role: Role,
    ): Effect.Effect<
      Invitation,
      SpaceNotFound | Forbidden | PersonalSpace | AlreadyMember | LimitReached
    >;
    forSpace(
      userId: string,
      spaceId: SpaceId,
    ): Effect.Effect<ReadonlyArray<Invitation>, SpaceNotFound | Forbidden>;
    revoke(
      userId: string,
      spaceId: SpaceId,
      id: InvitationId,
    ): Effect.Effect<void, SpaceNotFound | Forbidden | InvitationNotFound>;
    approve(
      userId: string,
      spaceId: SpaceId,
      id: InvitationId,
    ): Effect.Effect<
      Member,
      SpaceNotFound | Forbidden | InvitationNotFound | LimitReached
    >;
    /** The open invitations for the address of a signed-in user. */
    mine(email: string): Effect.Effect<ReadonlyArray<Invitation>>;
    accept(
      userId: string,
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
      const spaces = yield* SpacesService;
      const mailer = yield* Mailer;
      const sql = yield* SqlClient.SqlClient;
      const { appUrl } = yield* AppConfig;
      const app = appUrl.replace(/\/$/, "");

      /** The space of an owner; `Forbidden` for a member, not found for others. */
      const ownedBy = Effect.fn("InvitationsService.ownedBy")(function* (
        userId: string,
        spaceId: SpaceId,
      ) {
        const found = yield* spaces.findFor(userId, spaceId);
        if (Option.isNone(found))
          return yield* new SpaceNotFound({ id: spaceId });
        if (found.value.role !== "owner") return yield* new Forbidden();
        return found.value;
      });

      /** An invitation of the space that is still open, or not found. */
      const openOf = Effect.fn("InvitationsService.openOf")(function* (
        spaceId: SpaceId,
        id: InvitationId,
      ) {
        const row = yield* repo.find(id);
        if (
          Option.isNone(row) ||
          row.value.spaceId !== spaceId ||
          DateTime.toEpochMillis(row.value.expiresAt) <= Date.now()
        )
          return yield* new InvitationNotFound({ id });
        return row.value;
      });

      const invite = Effect.fn("InvitationsService.invite")(function* (
        userId: string,
        spaceId: SpaceId,
        rawEmail: string,
        role: Role,
      ) {
        const membership = yield* ownedBy(userId, spaceId);
        if (membership.space.kind === "personal")
          return yield* new PersonalSpace();
        const email = normalize(rawEmail);

        const members = yield* spaces.membersOf(userId, spaceId);
        if (members.some((m) => m.email === email))
          return yield* new AlreadyMember();

        const existing = yield* repo.findOpen(spaceId, email);
        const open = yield* repo.countOpen(spaceId);
        // renewing an open invitation does not take another place
        if (
          Option.isNone(existing) &&
          members.length + open >= MAX_MEMBERS_PER_SPACE
        )
          return yield* new LimitReached({ limit: MAX_MEMBERS_PER_SPACE });
        if (
          (yield* repo.countSentSince(userId, 3600)) >= MAX_INVITATIONS_PER_HOUR
        )
          return yield* new LimitReached({ limit: MAX_INVITATIONS_PER_HOUR });

        const id = crypto.randomUUID();
        if (Option.isSome(existing)) {
          yield* repo.renew(existing.value.id, role, INVITATION_DAYS);
        } else {
          yield* repo.insert({
            id,
            spaceId,
            email,
            role,
            invitedBy: userId,
            days: INVITATION_DAYS,
          });
        }
        const saved = yield* repo.findOpen(spaceId, email);
        const row = yield* Option.match(saved, {
          onNone: () => Effect.die("invitation vanished"),
          onSome: Effect.succeed,
        });
        const inviter = members.find((m) => m.userId === userId);
        yield* mailer.send({
          to: email,
          subject: `Zaproszenie do wspólnego budżetu „${membership.space.name}"`,
          text: `${who(inviter?.name ?? null, inviter?.email ?? "Ktoś")} zaprasza Cię do wspólnego budżetu „${membership.space.name}" w PLNing.\\n\\nZaloguj się tym adresem e-mail (${email}) pod adresem ${app}, a zaproszenie zobaczysz po zalogowaniu. Zaproszenie jest ważne ${INVITATION_DAYS} dni. Jeśli go nie oczekujesz, zignoruj tę wiadomość.`,
        });
        return present(row);
      });

      const forSpace = Effect.fn("InvitationsService.forSpace")(function* (
        userId: string,
        spaceId: SpaceId,
      ) {
        yield* ownedBy(userId, spaceId);
        return (yield* repo.forSpace(spaceId)).map(present);
      });

      const revoke = Effect.fn("InvitationsService.revoke")(function* (
        userId: string,
        spaceId: SpaceId,
        id: InvitationId,
      ) {
        yield* ownedBy(userId, spaceId);
        const row = yield* openOf(spaceId, id);
        const ended = yield* repo.advance(
          id,
          ["invited", "accepted"],
          row.status === "accepted" ? "rejected" : "revoked",
        );
        if (!ended) return yield* new InvitationNotFound({ id });
      });

      const approve = Effect.fn("InvitationsService.approve")(function* (
        userId: string,
        spaceId: SpaceId,
        id: InvitationId,
      ) {
        yield* ownedBy(userId, spaceId);
        const row = yield* openOf(spaceId, id);
        if (row.status !== "accepted" || row.acceptedBy === null)
          return yield* new InvitationNotFound({ id });
        const person = row.acceptedBy;
        const approved = yield* sql
          .withTransaction(
            Effect.gen(function* () {
              const members = yield* spaces.membersOf(userId, spaceId);
              // approved twice at once: the person is in already
              if (!members.some((m) => m.userId === person))
                yield* spaces.addMember(
                  spaceId,
                  person,
                  row.role,
                  MAX_MEMBERS_PER_SPACE,
                );
              yield* repo.advance(id, ["accepted"], "approved");
              return yield* spaces.membersOf(userId, spaceId);
            }),
          )
          .pipe(Effect.catchTag("SqlError", (error) => Effect.die(error)));
        const member = approved.find((m) => m.userId === person);
        if (member === undefined) return yield* new InvitationNotFound({ id });
        yield* mailer.send({
          to: row.email,
          subject: `Dołączyłeś do wspólnego budżetu „${row.spaceName}"`,
          text: `Właściciel zatwierdził Twoje dołączenie do wspólnego budżetu „${row.spaceName}". Otwórz PLNing (${app}) i wybierz go z listy przestrzeni.`,
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
        userId: string,
        email: string,
        id: InvitationId,
      ) {
        const row = yield* mineToAnswer(email, id);
        if (!(yield* repo.advance(id, ["invited"], "accepted", userId)))
          return yield* new InvitationNotFound({ id });
        const owners = yield* spaces.ownersOf(row.spaceId);
        yield* Effect.forEach(owners, (owner) =>
          mailer.send({
            to: owner.email,
            subject: `${row.email} chce dołączyć do „${row.spaceName}"`,
            text: `${row.email} przyjął zaproszenie do wspólnego budżetu „${row.spaceName}". Otwórz PLNing (${app}) i zatwierdź to w członkach przestrzeni, żeby osoba dostała dostęp. Jeśli nie znasz tego adresu, odrzuć zaproszenie.`,
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
        forSpace,
        revoke,
        approve,
        mine,
        accept,
        decline,
      });
    }),
  );
}
