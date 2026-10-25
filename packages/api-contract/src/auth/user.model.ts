import { Context, Schema } from "effect";
import { Model } from "effect/schema";
import { Name } from "../text.ts";
import { Uuid } from "../uuid.ts";

export const UserId = Uuid.pipe(Schema.brand("UserId"));
export type UserId = typeof UserId.Type;

/** An e-mail address. Stored and compared in lower case. */
export const Email = Schema.String.check(
  Schema.isMaxLength(254),
  Schema.isPattern(/^[^\s@]+@[^\s@]+\.[^\s@]+$/),
).annotate({ identifier: "Email" });

/** A person who signs in. There is no password: they prove the address. */
export class User extends Model.Class<User>("User")({
  id: Model.UuidV4Insert(UserId),
  email: Email,
  /** Shown to the people they share a space with; set later by the user. */
  name: Schema.NullOr(Name),
  createdAt: Model.DateTimeInsertFromDate,
}) {}

export const UserJson = User.json.annotate({ identifier: "User" });

/** The signed-in user of the current request. Provided by `Authenticated`. */
export class CurrentUser extends Context.Service<
  CurrentUser,
  { readonly user: User; readonly sessionId: string }
>()("bida/auth/CurrentUser") {}
