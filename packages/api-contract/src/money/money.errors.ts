import { Schema } from "effect";
import { UserId } from "../auth/user.model.ts";
import { Balance, Money } from "../money.ts";
import { Uuid } from "../uuid.ts";

// ---- not found (404): the thing does not exist or the user cannot see it ----

export class HouseholdNotFound extends Schema.TaggedError<HouseholdNotFound>()(
  "HouseholdNotFound",
  { id: Schema.String },
  { httpApiStatus: 404 },
) {}

export class PeriodNotFound extends Schema.TaggedError<PeriodNotFound>()(
  "PeriodNotFound",
  { id: Schema.String },
  { httpApiStatus: 404 },
) {}

export class EnvelopeNotFound extends Schema.TaggedError<EnvelopeNotFound>()(
  "EnvelopeNotFound",
  { id: Schema.String },
  { httpApiStatus: 404 },
) {}

export class ExpenseNotFound extends Schema.TaggedError<ExpenseNotFound>()(
  "ExpenseNotFound",
  { id: Schema.String },
  { httpApiStatus: 404 },
) {}

export class IncomeNotFound extends Schema.TaggedError<IncomeNotFound>()(
  "IncomeNotFound",
  { id: Schema.String },
  { httpApiStatus: 404 },
) {}

export class RuleNotFound extends Schema.TaggedError<RuleNotFound>()(
  "RuleNotFound",
  { id: Schema.String },
  { httpApiStatus: 404 },
) {}

/** Not there, or somebody has already dealt with it. */
export class TodoNotFound extends Schema.TaggedError<TodoNotFound>()(
  "TodoNotFound",
  { id: Schema.String },
  { httpApiStatus: 404 },
) {}

/** Not there, or its period is closed (the log only keeps open periods). */
export class LogEntryNotFound extends Schema.TaggedError<LogEntryNotFound>()(
  "LogEntryNotFound",
  { id: Schema.String },
  { httpApiStatus: 404 },
) {}

export class MemberNotFound extends Schema.TaggedError<MemberNotFound>()(
  "MemberNotFound",
  { userId: Schema.String },
  { httpApiStatus: 404 },
) {}

export class InvitationNotFound extends Schema.TaggedError<InvitationNotFound>()(
  "InvitationNotFound",
  { id: Schema.String },
  { httpApiStatus: 404 },
) {}

// ---- not allowed (403) -------------------------------------------------------

/** The user may see this, but not change it (e.g. only an owner can). */
export class Forbidden extends Schema.TaggedError<Forbidden>()(
  "Forbidden",
  {},
  { httpApiStatus: 403 },
) {}

// ---- invalid input (422) --------------------------------------------------------

/** An expense has to be dated in the current period and not later than now. */
export class DateOutsidePeriod extends Schema.TaggedError<DateOutsidePeriod>()(
  "DateOutsidePeriod",
  { periodId: Uuid, startsOn: Schema.String, endsOn: Schema.String },
  { httpApiStatus: 422 },
) {}

/**
 * The new end of the current period: `beforeToday` (a period cannot be
 * closed backwards), or `overlapsNext` (it would leave the next one no day).
 */
export class InvalidPeriodEnd extends Schema.TaggedError<InvalidPeriodEnd>()(
  "InvalidPeriodEnd",
  { reason: Schema.Literals(["beforeToday", "overlapsNext"]) },
  { httpApiStatus: 422 },
) {}

export class InvalidTimeZone extends Schema.TaggedError<InvalidTimeZone>()(
  "InvalidTimeZone",
  { timeZone: Schema.String },
  { httpApiStatus: 422 },
) {}

/** A cycle or schedule that misses its day, number of weeks or anchor. */
export class InvalidSchedule extends Schema.TaggedError<InvalidSchedule>()(
  "InvalidSchedule",
  {},
  { httpApiStatus: 422 },
) {}

/** Deleting an account needs its e-mail address typed in. */
export class ConfirmationMismatch extends Schema.TaggedError<ConfirmationMismatch>()(
  "ConfirmationMismatch",
  {},
  { httpApiStatus: 422 },
) {}

/** A limit was reached (members of a household, invitations per hour). */
export class LimitReached extends Schema.TaggedError<LimitReached>()(
  "LimitReached",
  { limit: Schema.Int },
  { httpApiStatus: 422 },
) {}

// ---- the rules about money (409) ---------------------------------------------------

/** More than there is: in the wallet (a transfer) or of the share (a withdrawal). */
export class NotEnoughMoney extends Schema.TaggedError<NotEnoughMoney>()(
  "NotEnoughMoney",
  { availableMinor: Balance },
  { httpApiStatus: 409 },
) {}

/** While the wallet is below zero no new transfers can come out of it. */
export class WalletNegative extends Schema.TaggedError<WalletNegative>()(
  "WalletNegative",
  { walletMinor: Balance },
  { httpApiStatus: 409 },
) {}

/**
 * The change would put the wallet below zero. Allowed only when the user
 * says so: an expense paid from an empty wallet, or an income corrected down.
 */
export class WalletWouldGoNegative extends Schema.TaggedError<WalletWouldGoNegative>()(
  "WalletWouldGoNegative",
  { walletMinor: Balance, neededMinor: Money },
  { httpApiStatus: 409 },
) {}

/**
 * The plan of the envelope is too small and there is no free money to raise
 * it ("Trzeba podnieść plan"). `transferMinor` is what to bring from the
 * wallet so the plan grows out of free money.
 */
export class PlanTooSmall extends Schema.TaggedError<PlanTooSmall>()(
  "PlanTooSmall",
  {
    envelopeId: Uuid,
    planShortMinor: Money,
    freeMinor: Balance,
    balanceMinor: Balance,
    transferMinor: Money,
  },
  { httpApiStatus: 409 },
) {}

/** The plan is fine, but the piggy bank holds less than the expense. */
export class NotEnoughInPeriod extends Schema.TaggedError<NotEnoughInPeriod>()(
  "NotEnoughInPeriod",
  { periodId: Uuid, balanceMinor: Balance, transferMinor: Money },
  { httpApiStatus: 409 },
) {}

/** A plan cannot go below what was already spent from the envelope. */
export class PlanBelowSpent extends Schema.TaggedError<PlanBelowSpent>()(
  "PlanBelowSpent",
  { envelopeId: Uuid, spentMinor: Money },
  { httpApiStatus: 409 },
) {}

/** A closed period is frozen: only the title of an expense can change. */
export class PeriodClosed extends Schema.TaggedError<PeriodClosed>()(
  "PeriodClosed",
  { periodId: Uuid },
  { httpApiStatus: 409 },
) {}

/** Money is spent only from the current period; the next one is for planning. */
export class PeriodNotCurrent extends Schema.TaggedError<PeriodNotCurrent>()(
  "PeriodNotCurrent",
  { periodId: Uuid },
  { httpApiStatus: 409 },
) {}

/** The next period is already open. */
export class NextPeriodOpen extends Schema.TaggedError<NextPeriodOpen>()(
  "NextPeriodOpen",
  { periodId: Uuid },
  { httpApiStatus: 409 },
) {}

export const NegativeShareEntry = Schema.Struct({
  householdId: Uuid,
  householdName: Schema.String,
  periodId: Uuid,
  userId: UserId,
  name: Schema.String,
  shareMinor: Balance,
}).annotate({ identifier: "NegativeShareEntry" });

/**
 * Somebody spent more than they put in, and that blocks leaving, deleting the
 * household or the account. Lists who has to even out where.
 */
export class NegativeShare extends Schema.TaggedError<NegativeShare>()(
  "NegativeShare",
  { entries: Schema.Array(NegativeShareEntry) },
  { httpApiStatus: 409 },
) {}

/** A household needs at least one owner. */
export class LastOwner extends Schema.TaggedError<LastOwner>()(
  "LastOwner",
  {},
  { httpApiStatus: 409 },
) {}

/** The address already belongs to a member of the household. */
export class AlreadyMember extends Schema.TaggedError<AlreadyMember>()(
  "AlreadyMember",
  {},
  { httpApiStatus: 409 },
) {}

/** A frozen member cannot spend until their share is evened out. */
export class MemberFrozen extends Schema.TaggedError<MemberFrozen>()(
  "MemberFrozen",
  {},
  { httpApiStatus: 409 },
) {}

/** Envelope names are unique in a household, whatever the case. */
export class DuplicateEnvelopeName extends Schema.TaggedError<DuplicateEnvelopeName>()(
  "DuplicateEnvelopeName",
  { name: Schema.String },
  { httpApiStatus: 409 },
) {}

/** An envelope with expenses is archived, not deleted. */
export class EnvelopeHasExpenses extends Schema.TaggedError<EnvelopeHasExpenses>()(
  "EnvelopeHasExpenses",
  { id: Uuid },
  { httpApiStatus: 409 },
) {}

/** A household keeps at least one active envelope. */
export class LastEnvelope extends Schema.TaggedError<LastEnvelope>()(
  "LastEnvelope",
  {},
  { httpApiStatus: 409 },
) {}

/** The change cannot be undone: what it touched is gone, or undoing it breaks a rule. */
export class CannotUndo extends Schema.TaggedError<CannotUndo>()(
  "CannotUndo",
  { reason: Schema.String },
  { httpApiStatus: 409 },
) {}
