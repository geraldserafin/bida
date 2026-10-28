import { Schema } from "effect";
import { EnvelopeId, Role } from "../envelopes/envelope.model.ts";
import { Balance, Money } from "../money.ts";
import { IsoDate } from "../text.ts";

/**
 * How much is in an envelope over a stretch of time. The balance rolls over:
 * `openingMinor` is what was left before the stretch began.
 *
 * For a top-level envelope everything includes its sub-envelopes, so
 * `balanceMinor` is all the money in it; `freeMinor` is the part that is not
 * assigned to a sub-envelope. A sub-envelope has `freeMinor` = `balanceMinor`.
 */
export const EnvelopeFigures = Schema.Struct({
  envelopeId: EnvelopeId,
  parentId: Schema.NullOr(EnvelopeId),
  openingMinor: Balance,
  /** Put in during the stretch, minus what was taken back. */
  allocatedMinor: Balance,
  spentMinor: Money,
  /** Opening plus allocated minus spent. Negative when overspent. */
  balanceMinor: Balance,
  freeMinor: Balance,
  /** What the user who asks may do with the envelope. */
  role: Role,
  /** How many people share the envelope; 1 when it is only theirs. */
  memberCount: Schema.Int,
}).annotate({ identifier: "EnvelopeFigures" });
export type EnvelopeFigures = typeof EnvelopeFigures.Type;

/** The state of the user's money over a stretch of time (usually a month). */
export const Overview = Schema.Struct({
  from: IsoDate,
  to: IsoDate,
  /** Income received in the stretch. */
  incomeMinor: Money,
  /** What the user put into top-level envelopes in the stretch, net. */
  allocatedMinor: Balance,
  /** What the user spent in the stretch. */
  spentMinor: Money,
  /** Not yet put into an envelope, at the end of the stretch. Can be negative. */
  poolMinor: Balance,
  envelopes: Schema.Array(EnvelopeFigures),
}).annotate({ identifier: "Overview" });
export type Overview = typeof Overview.Type;

/** One month of the user's history. */
export const MonthSummary = Schema.Struct({
  from: IsoDate,
  to: IsoDate,
  incomeMinor: Money,
  allocatedMinor: Balance,
  spentMinor: Money,
}).annotate({ identifier: "MonthSummary" });
export type MonthSummary = typeof MonthSummary.Type;
