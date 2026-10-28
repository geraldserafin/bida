import { Schema } from "effect";

/**
 * Largest amount accepted, in minor units (grosze). Keeps numbers exactly
 * representable in JSON and inside the database column.
 */
export const MAX_MINOR = 1_000_000_000_000;

/** Amount of money in minor units, never negative. */
export const Money = Schema.Int.check(
  Schema.isGreaterThanOrEqualTo(0),
  Schema.isLessThanOrEqualTo(MAX_MINOR),
);

/** Amount of money in minor units, greater than zero. */
export const PositiveMoney = Schema.Int.check(
  Schema.isGreaterThan(0),
  Schema.isLessThanOrEqualTo(MAX_MINOR),
);

/** Amount of money in minor units that is not zero; a negative one takes money back. */
export const NonZeroMoney = Schema.Int.check(
  Schema.isBetween({ minimum: -MAX_MINOR, maximum: MAX_MINOR }),
  Schema.makeFilter((n) => n !== 0 || "a non-zero amount", {
    expected: "a non-zero amount",
  }),
);

/** A balance in minor units: can be negative when more was spent than there was. */
export const Balance = Schema.Int;
