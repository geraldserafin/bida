import { Schema } from "effect";

export class SpaceNotFound extends Schema.TaggedError<SpaceNotFound>()(
  "SpaceNotFound",
  { id: Schema.String },
  { httpApiStatus: 404 },
) {}

/** The user is in the space, but the action is for owners only. */
export class Forbidden extends Schema.TaggedError<Forbidden>()(
  "Forbidden",
  {},
  { httpApiStatus: 403 },
) {}

export class MemberNotFound extends Schema.TaggedError<MemberNotFound>()(
  "MemberNotFound",
  { userId: Schema.String },
  { httpApiStatus: 404 },
) {}

/** A space needs at least one owner. */
export class LastOwner extends Schema.TaggedError<LastOwner>()(
  "LastOwner",
  {},
  { httpApiStatus: 409 },
) {}

/** Not for personal spaces: they cannot be shared, left or deleted. */
export class PersonalSpace extends Schema.TaggedError<PersonalSpace>()(
  "PersonalSpace",
  {},
  { httpApiStatus: 409 },
) {}

/** Other people are still in the space, so it cannot be deleted. */
export class SpaceNotEmpty extends Schema.TaggedError<SpaceNotEmpty>()(
  "SpaceNotEmpty",
  {},
  { httpApiStatus: 409 },
) {}

/** A limit was reached (spaces per user, members per space, invitations). */
export class LimitReached extends Schema.TaggedError<LimitReached>()(
  "LimitReached",
  { limit: Schema.Int },
  { httpApiStatus: 422 },
) {}
