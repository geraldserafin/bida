import { Schema } from "effect";

export class MemberNotFound extends Schema.TaggedError<MemberNotFound>()(
  "MemberNotFound",
  { userId: Schema.String },
  { httpApiStatus: 404 },
) {}

/** An envelope needs at least one owner. */
export class LastOwner extends Schema.TaggedError<LastOwner>()(
  "LastOwner",
  {},
  { httpApiStatus: 409 },
) {}

/** Only top-level envelopes are shared; a sub-envelope goes with its parent. */
export class NotShareable extends Schema.TaggedError<NotShareable>()(
  "NotShareable",
  {},
  { httpApiStatus: 422 },
) {}

/** The address already belongs to a member of the envelope. */
export class AlreadyMember extends Schema.TaggedError<AlreadyMember>()(
  "AlreadyMember",
  {},
  { httpApiStatus: 409 },
) {}

/** A limit was reached (members of an envelope, invitations per hour). */
export class LimitReached extends Schema.TaggedError<LimitReached>()(
  "LimitReached",
  { limit: Schema.Int },
  { httpApiStatus: 422 },
) {}

export class InvitationNotFound extends Schema.TaggedError<InvitationNotFound>()(
  "InvitationNotFound",
  { id: Schema.String },
  { httpApiStatus: 404 },
) {}
