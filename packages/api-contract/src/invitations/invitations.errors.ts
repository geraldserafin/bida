import { Schema } from "effect";

export class InvitationNotFound extends Schema.TaggedError<InvitationNotFound>()(
  "InvitationNotFound",
  { id: Schema.String },
  { httpApiStatus: 404 },
) {}

/** The address already belongs to a member of the space. */
export class AlreadyMember extends Schema.TaggedError<AlreadyMember>()(
  "AlreadyMember",
  {},
  { httpApiStatus: 409 },
) {}
