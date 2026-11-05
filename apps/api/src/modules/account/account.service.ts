import { ConfirmationMismatch, User, type UserId } from "@bida/api-contract";
import { DateTime, Effect } from "effect";
import { households as householdsModule } from "../households/households.module.ts";
import {
  householdKey,
  inTx,
  negativeShares,
  removeMember,
  store,
  userOf,
  walletKey,
} from "../ledger/ledger.module.ts";

export const setName = Effect.fn("account.setName")(function* (
  userId: UserId,
  name: string | null,
) {
  const trimmed = name === null || name.trim() === "" ? null : name.trim();
  const row = yield* store.setUserName(userId, trimmed);
  if (row === undefined) return yield* Effect.die("signed-in user is gone");
  return new User({
    id: row.id as UserId,
    email: row.email,
    name: row.name,
    createdAt: DateTime.makeUnsafe(row.createdAt),
  });
});

/**
 * F04: confirmed by typing the address (there are no passwords). Blocked
 * while the user has a negative share anywhere. Households where they are
 * alone go; elsewhere their positive shares stay as nobody's money, and when
 * they were the last owner the longest member becomes one.
 */
export const remove = Effect.fn("account.remove")(function* (
  userId: UserId,
  email: string,
) {
  const user = yield* userOf(userId);
  if (email.trim().toLowerCase() !== user.email)
    return yield* new ConfirmationMismatch();
  const households = yield* store.householdsOf(userId);
  yield* inTx(
    [walletKey(userId), ...households.map((h) => householdKey(h.id))],
    Effect.gen(function* () {
      const negative = [];
      for (const h of households)
        negative.push(...(yield* negativeShares(h, [userId])));
      if (negative.length > 0)
        return yield* householdsModule.negativeShareError(negative);
      for (const h of households) {
        const members = yield* store.membersOf(h.id);
        if (members.length === 1) {
          yield* householdsModule.removeHousehold(h);
          continue;
        }
        const me = members.find((m) => m.userId === userId);
        yield* removeMember(h, user, "forfeit");
        const rest = members.filter((m) => m.userId !== userId);
        if (me?.role === "owner" && !rest.some((m) => m.role === "owner")) {
          const longest = rest[0];
          if (longest !== undefined)
            yield* store.setRole(h.id, longest.userId, "owner");
        }
      }
      yield* store.deleteUser(userId);
    }),
  );
});
