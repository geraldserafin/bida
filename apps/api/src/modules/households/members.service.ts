import {
  AlreadyMember,
  Forbidden,
  INVITATION_DAYS,
  InvitationNotFound,
  LastOwner,
  LimitReached,
  MAX_INVITATIONS_PER_HOUR,
  MAX_MEMBERS_PER_HOUSEHOLD,
  MemberNotFound,
  type Role,
  type UserId,
} from "@bida/api-contract";
import { Effect } from "effect";
import { AppConfig } from "../../platform/config.ts";
import { Mailer, notify } from "../../platform/mailer.ts";
import type { HouseholdRow, MemberRow } from "../ledger/ledger.module.ts";
import {
  bankOf,
  householdFor,
  householdJson,
  householdKey,
  inTx,
  invitationJson,
  memberJson,
  nameOf,
  negativeShares,
  openOf,
  ownerOf,
  removeMember,
  shareOf,
  store,
  userOf,
  walletKey,
} from "../ledger/ledger.module.ts";
import { negativeShareError, removeHousehold } from "./households.service.ts";

const currentShares = Effect.fn("members.currentShares")(function* (
  h: HouseholdRow,
) {
  const { current } = yield* openOf(h.id);
  return (yield* bankOf(current)).ledger;
});

const present = Effect.fn("members.present")(function* (
  h: HouseholdRow,
  member: MemberRow,
) {
  const ledger = yield* currentShares(h);
  return memberJson(member, shareOf(ledger, member.userId));
});

export const list = Effect.fn("members.list")(function* (
  userId: UserId,
  householdId: string,
) {
  const { household } = yield* householdFor(userId, householdId);
  const ledger = yield* currentShares(household);
  return (yield* store.membersOf(householdId)).map((m) =>
    memberJson(m, shareOf(ledger, m.userId)),
  );
});

const targetOf = Effect.fn("members.targetOf")(function* (
  householdId: string,
  userId: string,
) {
  const member = yield* store.memberOf(householdId, userId);
  if (member === undefined) return yield* new MemberNotFound({ userId });
  return member;
});

/** F22: owners give and take the owner role; one owner always stays. */
export const setRole = Effect.fn("members.setRole")(function* (
  userId: UserId,
  householdId: string,
  targetId: string,
  role: Role,
) {
  const { household } = yield* ownerOf(userId, householdId);
  return yield* inTx(
    [householdKey(householdId)],
    Effect.gen(function* () {
      const target = yield* targetOf(householdId, targetId);
      if (target.role === "owner" && role === "member") {
        const owners = (yield* store.membersOf(householdId)).filter(
          (m) => m.role === "owner",
        );
        if (owners.length <= 1) return yield* new LastOwner();
      }
      yield* store.setRole(householdId, targetId, role);
      return yield* present(household, yield* targetOf(householdId, targetId));
    }),
  );
});

/** An owner removes a member; a positive share goes back to their wallet. */
export const remove = Effect.fn("members.remove")(function* (
  userId: UserId,
  householdId: string,
  targetId: string,
) {
  const { household } = yield* ownerOf(userId, householdId);
  if (targetId === userId) return yield* leave(userId, householdId, true);
  yield* inTx(
    [householdKey(householdId), walletKey(targetId)],
    Effect.gen(function* () {
      const target = yield* targetOf(householdId, targetId);
      if (target.role === "owner") {
        const owners = (yield* store.membersOf(householdId)).filter(
          (m) => m.role === "owner",
        );
        if (owners.length <= 1) return yield* new LastOwner();
      }
      const negative = yield* negativeShares(household, [targetId]);
      if (negative.length > 0) return yield* negativeShareError(negative);
      yield* removeMember(
        household,
        { id: target.userId, email: target.email, name: target.name },
        "return",
      );
    }),
  );
});

export const freeze = Effect.fn("members.freeze")(function* (
  userId: UserId,
  householdId: string,
  targetId: string,
  frozen: boolean,
) {
  const { household } = yield* ownerOf(userId, householdId);
  if (targetId === userId) return yield* new Forbidden();
  return yield* inTx(
    [householdKey(householdId)],
    Effect.gen(function* () {
      yield* targetOf(householdId, targetId);
      yield* store.setFrozen(householdId, targetId, frozen);
      return yield* present(household, yield* targetOf(householdId, targetId));
    }),
  );
});

/**
 * F36: not with a negative share. The shares are taken back to the wallet
 * when asked, otherwise they stay as nobody's money. The last owner gives the
 * role away first; the last member deletes the household.
 */
export const leave = Effect.fn("members.leave")(function* (
  userId: UserId,
  householdId: string,
  withdraw: boolean,
) {
  const { household, member, user } = yield* householdFor(userId, householdId);
  yield* inTx(
    [householdKey(householdId), walletKey(userId)],
    Effect.gen(function* () {
      const members = yield* store.membersOf(householdId);
      const negative = yield* negativeShares(household, [userId]);
      if (negative.length > 0) return yield* negativeShareError(negative);
      if (members.length === 1) return yield* removeHousehold(household);
      if (
        member.role === "owner" &&
        members.filter((m) => m.role === "owner").length <= 1
      )
        return yield* new LastOwner();
      yield* removeMember(household, user, withdraw ? "withdraw" : "forfeit");
    }),
  );
});

// ---- invitations -----------------------------------------------------------------------

const normalize = (email: string) => email.trim().toLowerCase();

export const invite = Effect.fn("members.invite")(function* (
  userId: UserId,
  householdId: string,
  rawEmail: string,
  role: Role,
) {
  const { household, user } = yield* ownerOf(userId, householdId);
  const email = normalize(rawEmail);
  const members = yield* store.membersOf(householdId);
  if (members.some((m) => m.email === email)) return yield* new AlreadyMember();
  const existing = yield* store.findOpenInvitation(householdId, email);
  const open = yield* store.countOpenInvitations(householdId);
  if (
    existing === undefined &&
    members.length + open >= MAX_MEMBERS_PER_HOUSEHOLD
  )
    return yield* new LimitReached({ limit: MAX_MEMBERS_PER_HOUSEHOLD });
  if (
    (yield* store.countInvitationsSentSince(userId, 3600)) >=
    MAX_INVITATIONS_PER_HOUR
  )
    return yield* new LimitReached({ limit: MAX_INVITATIONS_PER_HOUR });
  const id = existing?.id ?? crypto.randomUUID();
  if (existing !== undefined)
    yield* store.renewInvitation(id, role, INVITATION_DAYS);
  else
    yield* store.insertInvitation({
      id,
      householdId,
      email,
      role,
      invitedBy: userId,
      days: INVITATION_DAYS,
    });
  const row = yield* store.invitationById(id);
  if (row === undefined) return yield* Effect.die("invitation vanished");
  const mailer = yield* Mailer;
  const { appUrl } = yield* Effect.orDie(
    Effect.gen(function* () {
      return yield* AppConfig;
    }),
  );
  yield* notify(mailer, {
    to: email,
    subject: `Zaproszenie do gospodarstwa „${household.name}”`,
    text: `${nameOf(user)} zaprasza Cię do gospodarstwa „${household.name}” w PLNing.\n\nZaloguj się tym adresem e-mail (${email}) pod adresem ${appUrl.replace(/\/$/, "")}, a zaproszenie zobaczysz po zalogowaniu. Zaproszenie jest ważne ${INVITATION_DAYS} dni. Jeśli go nie oczekujesz, zignoruj tę wiadomość.`,
  });
  return invitationJson(row);
});

export const invitations = Effect.fn("members.invitations")(function* (
  userId: UserId,
  householdId: string,
) {
  yield* ownerOf(userId, householdId);
  return (yield* store.openInvitations(householdId)).map(invitationJson);
});

export const revoke = Effect.fn("members.revoke")(function* (
  userId: UserId,
  householdId: string,
  invitationId: string,
) {
  yield* ownerOf(userId, householdId);
  const row = yield* store.invitationById(invitationId);
  if (row === undefined || row.householdId !== householdId)
    return yield* new InvitationNotFound({ id: invitationId });
  yield* store.setInvitationStatus(invitationId, "revoked");
});

export const mine = Effect.fn("members.mine")(function* (userId: UserId) {
  const user = yield* userOf(userId);
  return (yield* store.invitationsFor(user.email)).map(invitationJson);
});

const forMe = Effect.fn("members.forMe")(function* (
  userId: UserId,
  invitationId: string,
) {
  const user = yield* userOf(userId);
  const row = yield* store.invitationById(invitationId);
  if (row === undefined || row.email !== user.email)
    return yield* new InvitationNotFound({ id: invitationId });
  return { user, row };
});

/** F13: accepting makes the user a member at once. */
export const accept = Effect.fn("members.accept")(function* (
  userId: UserId,
  invitationId: string,
) {
  const { row } = yield* forMe(userId, invitationId);
  yield* inTx(
    [householdKey(row.householdId)],
    Effect.gen(function* () {
      const members = yield* store.membersOf(row.householdId);
      if (!members.some((m) => m.userId === userId)) {
        if (members.length >= MAX_MEMBERS_PER_HOUSEHOLD)
          return yield* new LimitReached({ limit: MAX_MEMBERS_PER_HOUSEHOLD });
        yield* store.insertMember(row.householdId, userId, row.role);
      }
      yield* store.setInvitationStatus(invitationId, "accepted", userId);
    }),
  );
  const { household, member } = yield* householdFor(
    userId,
    row.householdId,
  ).pipe(Effect.orDie);
  return yield* householdJson(household, member);
});

export const decline = Effect.fn("members.decline")(function* (
  userId: UserId,
  invitationId: string,
) {
  yield* forMe(userId, invitationId);
  yield* store.setInvitationStatus(invitationId, "declined");
});
