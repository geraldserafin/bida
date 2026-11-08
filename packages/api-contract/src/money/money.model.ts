import { Schema } from "effect";
import { Email, UserId } from "../auth/user.model.ts";
import { Balance, Money, PositiveMoney } from "../money.ts";
import { IconKey, IsoDate, Name } from "../text.ts";
import { Uuid } from "../uuid.ts";

// Shapes are flat (no tagged unions) so the generated Dart client stays plain.

const Instant = Schema.DateTimeUtcFromString;

export const HexColor = Schema.String.check(
  Schema.isPattern(/^#[0-9a-fA-F]{6}$/),
);

/** `owner` manages members, invitations, the period and deleting; `member` transfers, plans and spends. */
export const Role = Schema.Literals(["owner", "member"]).annotate({
  identifier: "Role",
});
export type Role = typeof Role.Type;

// ---- households and periods ----------------------------------------------------------

/**
 * How the household cuts time into periods. `monthly` from `day` (1-31; past
 * the end of a short month it is the last day), `weeks`: every `weeks` weeks
 * from `anchorOn`, `manual`: the owner sets the end, a new period is as long
 * as the one before.
 */
export const Cycle = Schema.Struct({
  kind: Schema.Literals(["monthly", "weeks", "manual"]),
  day: Schema.NullOr(
    Schema.Int.check(Schema.isBetween({ minimum: 1, maximum: 31 })),
  ),
  weeks: Schema.NullOr(
    Schema.Int.check(Schema.isBetween({ minimum: 1, maximum: 52 })),
  ),
  anchorOn: Schema.NullOr(IsoDate),
}).annotate({ identifier: "Cycle" });
export type Cycle = typeof Cycle.Type;

export const PeriodStatus = Schema.Literals([
  "current",
  "next",
  "closed",
]).annotate({
  identifier: "PeriodStatus",
});

/** Both days are included, in the time zone of the household. */
export const Period = Schema.Struct({
  id: Uuid,
  householdId: Uuid,
  startsOn: IsoDate,
  endsOn: IsoDate,
  status: PeriodStatus,
}).annotate({ identifier: "Period" });
export type Period = typeof Period.Type;

export const Household = Schema.Struct({
  id: Uuid,
  name: Name,
  timeZone: Schema.String,
  cycle: Cycle,
  /** The role of the signed-in user. */
  role: Role,
  /** The signed-in user is frozen here. */
  frozen: Schema.Boolean,
  memberCount: Schema.Int,
  current: Period,
  next: Schema.NullOr(Period),
  /** Of the current piggy bank (F06). */
  balanceMinor: Balance,
  createdAt: Instant,
}).annotate({ identifier: "Household" });
export type Household = typeof Household.Type;

export const CreateHousehold = Schema.Struct({
  name: Schema.NonEmptyString.check(Schema.isMaxLength(50)),
  /** Monthly from the 1st when left out. */
  cycle: Schema.optional(Schema.NullOr(Cycle)),
  /** The end of the first period of a manual cycle. */
  firstEndsOn: Schema.optional(Schema.NullOr(IsoDate)),
  /** Europe/Warsaw when left out. */
  timeZone: Schema.optional(Schema.NullOr(Schema.String)),
  /** Names of the first envelopes; the default ones (F11) when left out. */
  envelopes: Schema.optional(
    Schema.NullOr(
      Schema.Array(Schema.NonEmptyString.check(Schema.isMaxLength(30))),
    ),
  ),
}).annotate({ identifier: "CreateHousehold" });
export type CreateHousehold = typeof CreateHousehold.Type;

export const RenameHousehold = Schema.Struct({
  name: Schema.NonEmptyString.check(Schema.isMaxLength(50)),
}).annotate({ identifier: "RenameHousehold" });

export const SetCycle = Schema.Struct({ cycle: Cycle }).annotate({
  identifier: "SetCycle",
});

export const SetPeriodEnd = Schema.Struct({ endsOn: IsoDate }).annotate({
  identifier: "SetPeriodEnd",
});

// ---- members and invitations ------------------------------------------------------

export const Member = Schema.Struct({
  userId: UserId,
  email: Email,
  name: Schema.NullOr(Name),
  role: Role,
  frozen: Schema.Boolean,
  joinedAt: Instant,
  /** In the current piggy bank (F14, F33). */
  shareMinor: Balance,
}).annotate({ identifier: "Member" });
export type Member = typeof Member.Type;

export const SetRole = Schema.Struct({ role: Role }).annotate({
  identifier: "SetRole",
});

export const Leave = Schema.Struct({
  /** Take the shares of the open piggy banks back to the wallet; otherwise they stay as nobody's money. */
  withdraw: Schema.Boolean,
}).annotate({ identifier: "Leave" });

export const Invitation = Schema.Struct({
  id: Uuid,
  householdId: Uuid,
  householdName: Name,
  email: Email,
  role: Role,
  invitedBy: Schema.NullOr(
    Schema.Struct({ email: Email, name: Schema.NullOr(Name) }),
  ),
  expiresAt: Instant,
  createdAt: Instant,
}).annotate({ identifier: "Invitation" });
export type Invitation = typeof Invitation.Type;

export const Invite = Schema.Struct({
  email: Email,
  role: Schema.optional(Schema.NullOr(Role)),
}).annotate({ identifier: "Invite" });

/** How long an invitation stays valid (F13). */
export const INVITATION_DAYS = 7;
export const MAX_INVITATIONS_PER_HOUR = 10;
export const MAX_MEMBERS_PER_HOUSEHOLD = 10;

// ---- envelopes and plans ------------------------------------------------------------

export const EnvelopeName = Schema.NonEmptyString.check(Schema.isMaxLength(30));

export const Envelope = Schema.Struct({
  id: Uuid,
  householdId: Uuid,
  name: EnvelopeName,
  color: HexColor,
  icon: Schema.NullOr(IconKey),
  position: Schema.Int,
  archived: Schema.Boolean,
}).annotate({ identifier: "Envelope" });
export type Envelope = typeof Envelope.Type;

export const SaveEnvelope = Schema.Struct({
  name: EnvelopeName,
  color: HexColor,
  icon: Schema.NullOr(IconKey),
}).annotate({ identifier: "SaveEnvelope" });
export type SaveEnvelope = typeof SaveEnvelope.Type;

/** The plan as the user sees it: one amount (the recurring part is kept by the server). */
export const SetPlan = Schema.Struct({ amountMinor: Money }).annotate({
  identifier: "SetPlan",
});

export const EnvelopeFigures = Schema.Struct({
  envelopeId: Uuid,
  name: Schema.String,
  color: Schema.String,
  icon: Schema.NullOr(Schema.String),
  archived: Schema.Boolean,
  planMinor: Money,
  manualMinor: Balance,
  recurringMinor: Money,
  spentMinor: Money,
  /** plan − spent; negative when it was overspent. */
  leftMinor: Balance,
  /** Of what was spent in the period, 0-100 (F17). */
  sharePercent: Schema.Number,
  /** Spent in the period before, when there is one (F23). */
  previousSpentMinor: Schema.NullOr(Money),
}).annotate({ identifier: "EnvelopeFigures" });

export const ShareFigures = Schema.Struct({
  /** Null: an account that was deleted. */
  userId: Schema.NullOr(UserId),
  name: Schema.String,
  member: Schema.Boolean,
  transfersMinor: Money,
  withdrawalsMinor: Money,
  forfeitedMinor: Money,
  spentMinor: Money,
  fromNobodyMinor: Money,
  shareMinor: Balance,
}).annotate({ identifier: "ShareFigures" });

export const Forecast = Schema.Struct({
  /** Spending without recurring expenses, carried to the end of the period. */
  variableMinor: Money,
  /** The recurring expenses of the period, from the rules. */
  recurringMinor: Money,
  projectedSpentMinor: Money,
  projectedBalanceMinor: Balance,
}).annotate({ identifier: "Forecast" });

/** One piggy bank (F16, F17, F18, F19, F23, F33). */
export const PeriodSummary = Schema.Struct({
  period: Period,
  transfersMinor: Money,
  withdrawalsMinor: Money,
  carryInMinor: Money,
  spentMinor: Money,
  estimatedSpentMinor: Money,
  /** przelewy − wycofania + niewydane z poprzedniego okresu − wydatki */
  balanceMinor: Balance,
  plansTotalMinor: Money,
  remainingPlansMinor: Money,
  /** balance − what the plans still hold; negative: the plans exceed the balance. */
  freeMinor: Balance,
  plansExceedBalance: Schema.Boolean,
  /** What went on to the next period (closed periods). */
  carryOutMinor: Schema.NullOr(Money),
  nobodyMinor: Money,
  nobodyLeftMinor: Money,
  envelopes: Schema.Array(EnvelopeFigures),
  shares: Schema.Array(ShareFigures),
  /** Current period with expenses on at least 3 different days only. */
  forecast: Schema.NullOr(Forecast),
}).annotate({ identifier: "PeriodSummary" });
export type PeriodSummary = typeof PeriodSummary.Type;

/** The happy event after a period closed (F35). */
export const ClosedSummary = Schema.Struct({
  periodId: Uuid,
  householdId: Uuid,
  householdName: Schema.String,
  startsOn: IsoDate,
  endsOn: IsoDate,
  transfersMinor: Money,
  withdrawalsMinor: Money,
  carryInMinor: Money,
  spentMinor: Money,
  carryOutMinor: Money,
}).annotate({ identifier: "ClosedSummary" });
export type ClosedSummary = typeof ClosedSummary.Type;

// ---- money moves ----------------------------------------------------------------------

export const Move = Schema.Struct({
  id: Uuid,
  periodId: Uuid,
  kind: Schema.Literals(["transfer", "withdrawal", "carry", "forfeit"]),
  userId: Schema.NullOr(UserId),
  userName: Schema.NullOr(Schema.String),
  amountMinor: PositiveMoney,
  madeAt: Instant,
  ruleId: Schema.NullOr(Uuid),
}).annotate({ identifier: "Move" });
export type Move = typeof Move.Type;

export const MoveMoney = Schema.Struct({ amountMinor: PositiveMoney }).annotate(
  {
    identifier: "MoveMoney",
  },
);

export const MoveResult = Schema.Struct({
  move: Move,
  walletMinor: Balance,
  /** The transfer used money of incomes that are not confirmed yet. */
  usedUnconfirmed: Schema.Boolean,
  /** "Plan przekracza saldo gospodarstwa" */
  plansExceedBalance: Schema.Boolean,
}).annotate({ identifier: "MoveResult" });

// ---- expenses -----------------------------------------------------------------------------

export const ForWhom = Schema.Literals(["member", "shared"]).annotate({
  identifier: "ForWhom",
});

export const Expense = Schema.Struct({
  id: Uuid,
  householdId: Uuid,
  periodId: Uuid,
  envelopeId: Uuid,
  createdBy: Schema.NullOr(UserId),
  authorName: Schema.String,
  amountMinor: PositiveMoney,
  spentAt: Instant,
  title: Schema.NullOr(Schema.String),
  forWhom: Schema.NullOr(ForWhom),
  forWhomUserId: Schema.NullOr(UserId),
  forWhomName: Schema.NullOr(Schema.String),
  estimated: Schema.Boolean,
  ruleId: Schema.NullOr(Uuid),
  createdAt: Instant,
  updatedAt: Instant,
}).annotate({ identifier: "Expense" });
export type Expense = typeof Expense.Type;

/**
 * What the user decided after a 409: raise the plan though there is no free
 * money, bring money from their wallet first, and let the wallet go below
 * zero for it.
 */
export const Decision = Schema.Struct({
  raisePlan: Schema.Boolean,
  transferMinor: Money,
  allowNegativeWallet: Schema.Boolean,
}).annotate({ identifier: "Decision" });
export type Decision = typeof Decision.Type;

export const ExpenseTitle = Schema.String.check(Schema.isMaxLength(200));

export const SaveExpense = Schema.Struct({
  envelopeId: Uuid,
  amountMinor: PositiveMoney,
  spentAt: Instant,
  title: Schema.NullOr(ExpenseTitle),
  forWhom: Schema.NullOr(ForWhom),
  forWhomUserId: Schema.NullOr(UserId),
  decision: Schema.optional(Schema.NullOr(Decision)),
}).annotate({ identifier: "SaveExpense" });
export type SaveExpense = typeof SaveExpense.Type;

export const ExpenseResult = Schema.Struct({
  expense: Expense,
  /** What came from the wallet of the user for it. */
  transferredMinor: Money,
  /** By how much the plan of the envelope went up. */
  raisedPlanMinor: Money,
  plansExceedBalance: Schema.Boolean,
}).annotate({ identifier: "ExpenseResult" });

// ---- the wallet -------------------------------------------------------------------------------

export const Wallet = Schema.Struct({
  balanceMinor: Balance,
  /** "w tym niepotwierdzone" */
  unconfirmedMinor: Money,
}).annotate({ identifier: "Wallet" });
export type Wallet = typeof Wallet.Type;

export const WalletEntry = Schema.Struct({
  id: Uuid,
  kind: Schema.Literals(["income", "transfer", "withdrawal", "return"]),
  amountMinor: PositiveMoney,
  onDate: IsoDate,
  note: Schema.NullOr(Schema.String),
  estimated: Schema.Boolean,
  householdId: Schema.NullOr(Uuid),
  householdName: Schema.NullOr(Schema.String),
  ruleId: Schema.NullOr(Uuid),
  createdAt: Instant,
}).annotate({ identifier: "WalletEntry" });
export type WalletEntry = typeof WalletEntry.Type;

export const IncomeNote = Schema.String.check(Schema.isMaxLength(200));

export const CreateIncome = Schema.Struct({
  amountMinor: PositiveMoney,
  onDate: IsoDate,
  note: Schema.NullOr(IncomeNote),
  estimated: Schema.Boolean,
}).annotate({ identifier: "CreateIncome" });
export type CreateIncome = typeof CreateIncome.Type;

/**
 * When a correction down would put the wallet below zero: leave the minus
 * until the next income, or first take the missing amount back from a
 * period (up to the share there).
 */
export const Correction = Schema.Struct({
  allowNegative: Schema.Boolean,
  withdrawFromPeriodId: Schema.NullOr(Uuid),
}).annotate({ identifier: "Correction" });
export type Correction = typeof Correction.Type;

export const UpdateIncome = Schema.Struct({
  amountMinor: PositiveMoney,
  onDate: IsoDate,
  note: Schema.NullOr(IncomeNote),
  estimated: Schema.Boolean,
  correction: Schema.optional(Schema.NullOr(Correction)),
}).annotate({ identifier: "UpdateIncome" });
export type UpdateIncome = typeof UpdateIncome.Type;

export const ConfirmIncome = Schema.Struct({
  amountMinor: PositiveMoney,
  correction: Schema.optional(Schema.NullOr(Correction)),
}).annotate({ identifier: "ConfirmIncome" });

export const RemoveIncome = Schema.Struct({
  correction: Schema.optional(Schema.NullOr(Correction)),
}).annotate({ identifier: "RemoveIncome" });

// ---- recurring rules ----------------------------------------------------------------------------

export const RuleKind = Schema.Literals([
  "income",
  "transfer",
  "expense",
]).annotate({
  identifier: "RuleKind",
});

export const RecurringRule = Schema.Struct({
  id: Uuid,
  kind: RuleKind,
  /** Who made it: owner of the wallet, or author of the expenses. */
  userId: UserId,
  householdId: Schema.NullOr(Uuid),
  envelopeId: Schema.NullOr(Uuid),
  name: Name,
  amountMinor: PositiveMoney,
  estimated: Schema.Boolean,
  frequency: Schema.Literals(["monthly", "weeks"]),
  dayOfMonth: Schema.NullOr(Schema.Int),
  everyWeeks: Schema.NullOr(Schema.Int),
  anchorOn: Schema.NullOr(IsoDate),
  startsOn: IsoDate,
  /** Transfers: the period of the day, or the one after it. */
  target: Schema.NullOr(Schema.Literals(["current", "next"])),
  /** Transfers: the income rule whose every certain occurrence goes on whole. */
  incomeRuleId: Schema.NullOr(Uuid),
  active: Schema.Boolean,
}).annotate({ identifier: "RecurringRule" });
export type RecurringRule = typeof RecurringRule.Type;

export const SaveRule = Schema.Struct({
  kind: RuleKind,
  householdId: Schema.NullOr(Uuid),
  envelopeId: Schema.NullOr(Uuid),
  name: Name,
  amountMinor: PositiveMoney,
  estimated: Schema.Boolean,
  frequency: Schema.Literals(["monthly", "weeks"]),
  dayOfMonth: Schema.NullOr(
    Schema.Int.check(Schema.isBetween({ minimum: 1, maximum: 31 })),
  ),
  everyWeeks: Schema.NullOr(
    Schema.Int.check(Schema.isBetween({ minimum: 1, maximum: 52 })),
  ),
  anchorOn: Schema.NullOr(IsoDate),
  /** Today when left out. */
  startsOn: Schema.optional(Schema.NullOr(IsoDate)),
  target: Schema.NullOr(Schema.Literals(["current", "next"])),
  /**
   * Transfers only: follow this income rule of the user. Each occurrence of
   * the income, once its amount is certain, goes on whole into the
   * household; amount and schedule are then taken from the income.
   */
  incomeRuleId: Schema.optional(Schema.NullOr(Uuid)),
  active: Schema.Boolean,
}).annotate({ identifier: "SaveRule" });
export type SaveRule = typeof SaveRule.Type;

export const ApplyRule = Schema.Struct({
  /** The real amount, for an estimated income or expense applied early. */
  amountMinor: Schema.NullOr(PositiveMoney),
}).annotate({ identifier: "ApplyRule" });

export const ApplyResult = Schema.Struct({
  /** Entries made. */
  applied: Schema.Int,
  /** Occurrences that went to the to-do list instead. */
  todo: Schema.Int,
}).annotate({ identifier: "ApplyResult" });

// ---- the to-do list ------------------------------------------------------------------------------

/**
 * `income_estimate`: an estimated income went in with its estimate, confirm
 * the real amount. `transfer_no_money`: a recurring transfer did not go, the
 * wallet was short. `expense_not_fit`: a recurring expense does not fit the
 * plan or the balance. `expense_estimate`: confirm the real amount of an
 * estimated expense (until the period ends). `expense_missed`: a recurring
 * expense fell in a period that closed before the app was opened.
 */
export const TodoKind = Schema.Literals([
  "income_estimate",
  "transfer_no_money",
  "expense_not_fit",
  "expense_estimate",
  "expense_missed",
]).annotate({ identifier: "TodoKind" });

export const TodoItem = Schema.Struct({
  id: Uuid,
  kind: TodoKind,
  householdId: Schema.NullOr(Uuid),
  householdName: Schema.NullOr(Schema.String),
  periodId: Schema.NullOr(Uuid),
  ruleId: Schema.NullOr(Uuid),
  /** The income or expense it is about. */
  refId: Schema.NullOr(Uuid),
  envelopeId: Schema.NullOr(Uuid),
  occurrenceOn: Schema.NullOr(IsoDate),
  amountMinor: PositiveMoney,
  title: Schema.NullOr(Schema.String),
  createdAt: Instant,
}).annotate({ identifier: "TodoItem" });
export type TodoItem = typeof TodoItem.Type;

export const ResolveTodo = Schema.Struct({
  amountMinor: PositiveMoney,
  /** For an expense (as in F08). */
  decision: Schema.optional(Schema.NullOr(Decision)),
  /** For an income corrected down. */
  correction: Schema.optional(Schema.NullOr(Correction)),
}).annotate({ identifier: "ResolveTodo" });
export type ResolveTodo = typeof ResolveTodo.Type;

export const SyncResult = Schema.Struct({
  closedPeriods: Schema.Int,
  openedPeriods: Schema.Int,
  incomes: Schema.Int,
  transfers: Schema.Int,
  expenses: Schema.Int,
  /** Open items in the to-do list of the user (the badge). */
  todo: Schema.Int,
  /** Closed periods the user has not seen yet. */
  summaries: Schema.Array(ClosedSummary),
}).annotate({ identifier: "SyncResult" });
export type SyncResult = typeof SyncResult.Type;

// ---- the change log ---------------------------------------------------------------------------------

export const LogEntry = Schema.Struct({
  id: Uuid,
  householdId: Uuid,
  periodId: Uuid,
  userId: Schema.NullOr(UserId),
  userName: Schema.String,
  action: Schema.String,
  summary: Schema.String,
  createdAt: Instant,
  undone: Schema.Boolean,
  /** The signed-in user may undo it. */
  canUndo: Schema.Boolean,
}).annotate({ identifier: "LogEntry" });
export type LogEntry = typeof LogEntry.Type;

// ---- the dashboard ---------------------------------------------------------------------------------

export const HouseholdOverview = Schema.Struct({
  id: Uuid,
  name: Schema.String,
  current: Period,
  balanceMinor: Balance,
  freeMinor: Balance,
  /** Spent from the household in the range asked for. */
  spentMinor: Money,
}).annotate({ identifier: "HouseholdOverview" });

export const Overview = Schema.Struct({
  wallet: Wallet,
  households: Schema.Array(HouseholdOverview),
  todo: Schema.Int,
}).annotate({ identifier: "Overview" });

// ---- the account ---------------------------------------------------------------------------------

export const DeleteAccount = Schema.Struct({
  /** The address of the account, typed in to confirm. */
  email: Email,
}).annotate({ identifier: "DeleteAccount" });

export const UpdateProfile = Schema.Struct({
  name: Schema.NullOr(Name),
}).annotate({ identifier: "UpdateProfile" });
