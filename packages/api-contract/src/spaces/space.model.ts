import { Context, Schema } from "effect";
import { Model } from "effect/schema";
import { Email, UserId } from "../auth/user.model.ts";
import { Currency } from "../currency/index.ts";
import { Name } from "../text.ts";
import { Uuid } from "../uuid.ts";

export const SpaceId = Uuid.pipe(Schema.brand("SpaceId"));
export type SpaceId = typeof SpaceId.Type;

/**
 * `personal` is the one budget every user has: it has a single member and
 * cannot be shared, left or deleted. `shared` is a budget of several people.
 */
export const SpaceKind = Schema.Literals(["personal", "shared"]).annotate({
  identifier: "SpaceKind",
});
export type SpaceKind = typeof SpaceKind.Type;

/** What a member may do in a space. */
export const Role = Schema.Literals(["owner", "member"]).annotate({
  identifier: "Role",
  description:
    "`owner` manages the space and its members; `member` works with the budget.",
});
export type Role = typeof Role.Type;

/**
 * A budget space: everything else (categories, periods, expenses, rules) lives
 * in exactly one space. Sharing a budget means sharing a space.
 */
export class Space extends Model.Class<Space>("Space")({
  id: Model.UuidV4Insert(SpaceId),
  name: Name,
  /** Currency of new periods and recurring rules when none is chosen. */
  defaultCurrency: Currency,
  kind: SpaceKind,
  createdAt: Model.DateTimeInsertFromDate,
  updatedAt: Model.DateTimeUpdateFromDate,
}) {}

export const SpaceJson = Space.json.annotate({ identifier: "Space" });

/** A space as one of its members sees it. */
export const MySpace = Schema.Struct({
  space: SpaceJson,
  /** The role of the user who asks. */
  role: Role,
  memberCount: Schema.Int,
}).annotate({ identifier: "MySpace" });
export type MySpace = typeof MySpace.Type;

export const SaveSpace = Schema.Struct({
  name: Name,
  defaultCurrency: Currency,
}).annotate({ identifier: "SaveSpace" });
export type SaveSpace = typeof SaveSpace.Type;

/** Somebody who works in a space. */
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

/** The space the current request works in. Provided by `SpaceContext`. */
export class CurrentSpace extends Context.Service<CurrentSpace, Space>()(
  "bida/spaces/CurrentSpace",
) {}

/** The signed-in user as a member of the current space. */
export class CurrentMember extends Context.Service<
  CurrentMember,
  { readonly userId: string; readonly role: Role }
>()("bida/spaces/CurrentMember") {}

/** Id of the space that exists from the start and holds data from before accounts. */
export const DEFAULT_SPACE_ID =
  "00000000-0000-4000-8000-000000000001" as SpaceId;

/** Limits that keep one account from filling the server. */
export const MAX_SPACES_PER_USER = 20;
export const MAX_MEMBERS_PER_SPACE = 10;
