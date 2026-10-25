import { Schema } from "effect";

/**
 * Largest amount accepted, in minor units. Keeps numbers exactly representable
 * in JSON and inside the database column.
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
