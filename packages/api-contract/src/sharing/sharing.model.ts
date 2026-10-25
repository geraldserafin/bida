import { Schema } from "effect";
import { Email, UserId } from "../auth/user.model.ts";
import { EnvelopeId, Role } from "../envelopes/envelope.model.ts";
import { Balance } from "../money.ts";
import { Name } from "../text.ts";
import { Uuid } from "../uuid.ts";

/** Somebody who shares an envelope. */
export const Member = Schema.Struct({
  userId: UserId,
  email: Email,
  name: Schema.NullOr(Name),
  role: Role,
  joinedAt: Schema.DateTimeUtcFromString,
}).annotate({ identifier: "Member" });
export type Member = typeof Member.Type;

export const SetRole = Schema.Struct({ role: Role }).annotate({
  identifier: "SetRole",
});
export type SetRole = typeof SetRole.Type;

/**
 * How much a member has put into an envelope, all time and net of what they
 * took back. Listed for the envelope and each of its sub-envelopes.
 */
export const Contribution = Schema.Struct({
  envelopeId: EnvelopeId,
  userId: UserId,
  amountMinor: Balance,
}).annotate({ identifier: "Contribution" });
export type Contribution = typeof Contribution.Type;

export const InvitationId = Uuid.pipe(Schema.brand("InvitationId"));
export type InvitationId = typeof InvitationId.Type;

/**
 * `invited`: waiting for the person to answer. `accepted`: they said yes and an
 * owner still has to approve before they get in. The other ends of an
 * invitation (approved, declined, rejected, revoked, expired) are not listed.
 */
export const InvitationStatus = Schema.Literals([
  "invited",
  "accepted",
]).annotate({ identifier: "InvitationStatus" });
export type InvitationStatus = typeof InvitationStatus.Type;

export const Invitation = Schema.Struct({
  id: InvitationId,
  envelopeId: EnvelopeId,
  envelopeName: Name,
  email: Email,
  role: Role,
  status: InvitationStatus,
  /** Who invited; empty when that person has left or deleted their account. */
  invitedBy: Schema.NullOr(
    Schema.Struct({ email: Email, name: Schema.NullOr(Name) }),
  ),
  /** Set once the invitation was accepted. */
  acceptedBy: Schema.NullOr(UserId),
  expiresAt: Schema.DateTimeUtcFromString,
  createdAt: Schema.DateTimeUtcFromString,
}).annotate({ identifier: "Invitation" });
export type Invitation = typeof Invitation.Type;

export const Invite = Schema.Struct({
  email: Email,
  role: Role,
}).annotate({ identifier: "Invite" });
export type Invite = typeof Invite.Type;

/** How long an invitation stays valid. */
export const INVITATION_DAYS = 14;
/** How many invitations one user can send in an hour. */
export const MAX_INVITATIONS_PER_HOUR = 10;
/** How many people can share one envelope. */
export const MAX_MEMBERS_PER_ENVELOPE = 10;
