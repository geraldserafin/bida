import type { CurrentSpace } from "@bida/api-contract";
import { CurrentMember, Forbidden } from "@bida/api-contract";
import { Effect } from "effect";

/** An effect that works inside the space of the current request. */
export type InSpace<A, E = never> = Effect.Effect<A, E, CurrentSpace>;

/** Lets the request through only when the user owns the space. */
export const requireOwner = Effect.flatMap(CurrentMember, ({ role }) =>
  role === "owner" ? Effect.void : Effect.fail(new Forbidden()),
);
