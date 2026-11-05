import {
  Forbidden,
  HouseholdNotFound,
  PeriodNotFound,
  type UserId,
} from "@bida/api-contract";
import { Effect } from "effect";
import { SqlClient } from "effect/sql";
import * as store from "./store.ts";

/**
 * Runs `effect` in one transaction after taking the locks. A failure rolls
 * everything back; a database failure is a defect.
 */
export const inTx = <A, E, R>(
  keys: ReadonlyArray<string>,
  effect: Effect.Effect<A, E, R>,
) =>
  Effect.gen(function* () {
    const sql = yield* SqlClient.SqlClient;
    return yield* sql.withTransaction(
      Effect.flatMap(store.lock(keys), () => effect),
    );
  }).pipe(
    Effect.catchTag("SqlError" as never, (error: unknown) => Effect.die(error)),
  ) as Effect.Effect<A, E, R | SqlClient.SqlClient>;

export const walletKey = (userId: string) => `w:${userId}`;
export const householdKey = (householdId: string) => `h:${householdId}`;

/** The signed-in user. */
export const userOf = Effect.fn("access.userOf")(function* (userId: UserId) {
  const user = yield* store.userById(userId);
  if (user === undefined) return yield* Effect.die("signed-in user is gone");
  return user;
});

/** A household of the user and their membership; not found for others. */
export const householdFor = Effect.fn("access.householdFor")(function* (
  userId: UserId,
  householdId: string,
) {
  const member = yield* store.memberOf(householdId, userId);
  const household =
    member === undefined ? undefined : yield* store.householdById(householdId);
  if (member === undefined || household === undefined)
    return yield* new HouseholdNotFound({ id: householdId });
  const user = yield* userOf(userId);
  return { household, member, user };
});

export const ownerOf = Effect.fn("access.ownerOf")(function* (
  userId: UserId,
  householdId: string,
) {
  const found = yield* householdFor(userId, householdId);
  if (found.member.role !== "owner") return yield* new Forbidden();
  return found;
});

/** A period of one of the user's households. */
export const periodFor = Effect.fn("access.periodFor")(function* (
  userId: UserId,
  periodId: string,
) {
  const period = yield* store.periodById(periodId);
  if (period === undefined) return yield* new PeriodNotFound({ id: periodId });
  const found = yield* householdFor(userId, period.householdId).pipe(
    Effect.catchTag("HouseholdNotFound", () =>
      Effect.fail(new PeriodNotFound({ id: periodId })),
    ),
  );
  return { ...found, period };
});
