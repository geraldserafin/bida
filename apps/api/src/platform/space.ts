import type { CurrentSpace } from "@bida/api-contract";
import type { Effect } from "effect";

/** An effect that works inside the space of the current request. */
export type InSpace<A, E = never> = Effect.Effect<A, E, CurrentSpace>;
