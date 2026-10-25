import { Schema } from "effect";
import { Email, UserId } from "../auth/user.model.ts";
import { Role, SpaceId } from "../spaces/space.model.ts";
import { Name } from "../text.ts";
import { Uuid } from "../uuid.ts";

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
  spaceId: SpaceId,
  spaceName: Name,
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
