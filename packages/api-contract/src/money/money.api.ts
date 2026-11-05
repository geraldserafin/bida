import { Schema } from "effect";
import {
  HttpApiEndpoint,
  HttpApiGroup,
  HttpApiSchema,
  OpenApi,
} from "effect/http-api";
import { Authenticated } from "../auth/authenticated.ts";
import { UserId, UserJson } from "../auth/user.model.ts";
import { wire } from "../errors.ts";
import { IsoDate } from "../text.ts";
import { Uuid } from "../uuid.ts";
import {
  AlreadyMember,
  CannotUndo,
  ConfirmationMismatch,
  DateOutsidePeriod,
  DuplicateEnvelopeName,
  EnvelopeHasExpenses,
  EnvelopeNotFound,
  ExpenseNotFound,
  Forbidden,
  HouseholdNotFound,
  IncomeNotFound,
  InvalidPeriodEnd,
  InvalidSchedule,
  InvalidTimeZone,
  InvitationNotFound,
  LastEnvelope,
  LastOwner,
  LimitReached,
  LogEntryNotFound,
  MemberFrozen,
  MemberNotFound,
  NegativeShare,
  NextPeriodOpen,
  NotEnoughInPeriod,
  NotEnoughMoney,
  PeriodClosed,
  PeriodNotCurrent,
  PeriodNotFound,
  PlanBelowSpent,
  PlanTooSmall,
  RuleNotFound,
  TodoNotFound,
  WalletNegative,
  WalletWouldGoNegative,
} from "./money.errors.ts";
import {
  ApplyResult,
  ApplyRule,
  ClosedSummary,
  ConfirmIncome,
  CreateHousehold,
  CreateIncome,
  DeleteAccount,
  Envelope,
  Expense,
  ExpenseResult,
  Household,
  Invitation,
  Invite,
  Leave,
  LogEntry,
  Member,
  Move,
  MoveMoney,
  MoveResult,
  Overview,
  Period,
  PeriodSummary,
  RecurringRule,
  RemoveIncome,
  RenameHousehold,
  ResolveTodo,
  SaveEnvelope,
  SaveExpense,
  SaveRule,
  SetCycle,
  SetPeriodEnd,
  SetPlan,
  SetRole,
  SyncResult,
  TodoItem,
  UpdateIncome,
  UpdateProfile,
  Wallet,
  WalletEntry,
} from "./money.model.ts";

const ids = { id: Uuid };
const page = {
  limit: Schema.optional(
    Schema.NumberFromString.check(
      Schema.isInt(),
      Schema.isBetween({ minimum: 1, maximum: 200 }),
    ),
  ),
  offset: Schema.optional(
    Schema.NumberFromString.check(
      Schema.isInt(),
      Schema.isGreaterThanOrEqualTo(0),
    ),
  ),
};
const note = (summary: string, description?: string) =>
  OpenApi.annotations(
    description === undefined ? { summary } : { summary, description },
  );

/** What a decision about money can come back with (F08 steps). */
const expenseErrors = [
  wire(PlanTooSmall),
  wire(NotEnoughInPeriod),
  wire(WalletWouldGoNegative),
  wire(DateOutsidePeriod),
  wire(PeriodNotCurrent),
  wire(PeriodClosed),
  wire(MemberFrozen),
  wire(MemberNotFound),
  wire(EnvelopeNotFound),
  wire(NotEnoughMoney),
  wire(WalletNegative),
] as const;

export class SyncApi extends HttpApiGroup.make("sync")
  .add(
    HttpApiEndpoint.post("run", "/sync", { success: SyncResult }).annotateMerge(
      note(
        "Do what is due (call on every app start)",
        "Nothing happens on the server in the background. In this order: closes the periods that ended (their rest goes on as nobody's money, their log entries go), opens the new ones with the plans copied, then the user's recurring incomes, their recurring transfers and the recurring expenses of their households. Running it again does nothing twice. What needs a decision goes to the to-do list.",
      ),
    ),
    HttpApiEndpoint.get("summaries", "/summaries", {
      success: Schema.Array(ClosedSummary),
    }).annotateMerge(note("Closed periods the user has not seen yet (F35)")),
    HttpApiEndpoint.post("seen", "/periods/:id/summary/seen", {
      params: ids,
      error: wire(PeriodNotFound),
    }).annotateMerge(note("The user has seen the summary of a closed period")),
    HttpApiEndpoint.get("todo", "/todo", {
      success: Schema.Array(TodoItem),
    }).annotateMerge(
      note(
        "The to-do list (F34)",
        "Matters of the user's wallet and of their households, oldest first.",
      ),
    ),
    HttpApiEndpoint.post("resolve", "/todo/:id/resolve", {
      params: ids,
      payload: ResolveTodo,
      error: [
        wire(TodoNotFound),
        ...expenseErrors,
        wire(HouseholdNotFound),
        wire(PeriodNotFound),
        wire(IncomeNotFound),
        wire(Forbidden),
      ],
    }).annotateMerge(
      note(
        "Deal with an item",
        "Confirms the amount of an estimated income or expense, makes the transfer that could not go, or adds the expense that did not fit, with the same steps as F08. Gone for everybody once done.",
      ),
    ),
    HttpApiEndpoint.post("dismiss", "/todo/:id/dismiss", {
      params: ids,
      error: wire(TodoNotFound),
    }).annotateMerge(
      note(
        "Leave an item as it is",
        "An estimate stays as estimated; a skipped transfer or expense is not made.",
      ),
    ),
    HttpApiEndpoint.get("overview", "/overview", {
      query: { from: IsoDate, to: IsoDate },
      success: Overview,
    }).annotateMerge(
      note(
        "The dashboard (F38)",
        "The wallet as of today; every household with its current piggy bank and what was spent from it between `from` and `to` (both included).",
      ),
    ),
  )
  .middleware(Authenticated)
  .annotateMerge(OpenApi.annotations({ title: "Sync" })) {}

export class HouseholdsApi extends HttpApiGroup.make("households")
  .add(
    HttpApiEndpoint.get("list", "/households", {
      success: Schema.Array(Household),
    }).annotateMerge(note("My households (F06)")),
    HttpApiEndpoint.post("create", "/households", {
      payload: CreateHousehold,
      success: Household.pipe(HttpApiSchema.status(201)),
      error: [wire(InvalidTimeZone), wire(InvalidSchedule)],
    }).annotateMerge(
      note(
        "Create a household (F05)",
        "The user becomes its owner. It gets the default envelopes and opens its first, current period.",
      ),
    ),
    HttpApiEndpoint.get("get", "/households/:id", {
      params: ids,
      success: Household,
      error: wire(HouseholdNotFound),
    }).annotateMerge(note("Get a household")),
    HttpApiEndpoint.put("rename", "/households/:id", {
      params: ids,
      payload: RenameHousehold,
      success: Household,
      error: [wire(HouseholdNotFound), wire(Forbidden)],
    }).annotateMerge(note("Rename a household", "Owners only.")),
    HttpApiEndpoint.delete("delete", "/households/:id", {
      params: ids,
      error: [wire(HouseholdNotFound), wire(Forbidden), wire(NegativeShare)],
    }).annotateMerge(
      note(
        "Delete a household",
        "Owners only, and not while anybody has a negative share. Positive shares go back to the wallets.",
      ),
    ),
    HttpApiEndpoint.put("setCycle", "/households/:id/cycle", {
      params: ids,
      payload: SetCycle,
      success: Household,
      error: [wire(HouseholdNotFound), wire(Forbidden), wire(InvalidSchedule)],
    }).annotateMerge(
      note(
        "Change the cycle of periods",
        "Owners only. Applies from the end of the current period; an open next period is recounted.",
      ),
    ),
    HttpApiEndpoint.get("periods", "/households/:id/periods", {
      params: ids,
      success: Schema.Array(Period),
      error: wire(HouseholdNotFound),
    }).annotateMerge(note("The periods of a household, newest first")),
    HttpApiEndpoint.post("openNext", "/households/:id/periods/next", {
      params: ids,
      success: Period.pipe(HttpApiSchema.status(201)),
      error: [wire(HouseholdNotFound), wire(NextPeriodOpen)],
    }).annotateMerge(
      note(
        "Open the next period",
        "Any member. Its plans are copied from the current one.",
      ),
    ),
    HttpApiEndpoint.get("period", "/periods/:id", {
      params: ids,
      query: {
        /** Only the expenses for a member (their id), `shared` or `none`, in the envelope figures. */
        forWhom: Schema.optional(Schema.String),
      },
      success: PeriodSummary,
      error: wire(PeriodNotFound),
    }).annotateMerge(note("The piggy bank of a period (F16, F17, F18, F23)")),
    HttpApiEndpoint.put("setEnd", "/periods/:id/end", {
      params: ids,
      payload: SetPeriodEnd,
      success: Period,
      error: [
        wire(PeriodNotFound),
        wire(Forbidden),
        wire(PeriodNotCurrent),
        wire(InvalidPeriodEnd),
      ],
    }).annotateMerge(
      note(
        "Move the end of the current period",
        "Owners only. Not before today and leaving the next period at least a day. The next periods count from the new end; the money of the next period moves with it.",
      ),
    ),
    HttpApiEndpoint.get("moves", "/periods/:id/moves", {
      params: ids,
      success: Schema.Array(Move),
      error: wire(PeriodNotFound),
    }).annotateMerge(note("Transfers, withdrawals and the carry of a period")),
    HttpApiEndpoint.post("transfer", "/periods/:id/transfers", {
      params: ids,
      payload: MoveMoney,
      success: MoveResult.pipe(HttpApiSchema.status(201)),
      error: [
        wire(PeriodNotFound),
        wire(PeriodClosed),
        wire(NotEnoughMoney),
        wire(WalletNegative),
      ],
    }).annotateMerge(
      note(
        "Transfer from the wallet into a period (F32)",
        "The current or the next one. Not more than the wallet holds, and not while the wallet is below zero.",
      ),
    ),
    HttpApiEndpoint.post("withdraw", "/periods/:id/withdrawals", {
      params: ids,
      payload: MoveMoney,
      success: MoveResult.pipe(HttpApiSchema.status(201)),
      error: [wire(PeriodNotFound), wire(PeriodClosed), wire(NotEnoughMoney)],
    }).annotateMerge(
      note(
        "Take money back to the wallet (F32)",
        "At most the user's share and at most what is in the piggy bank.",
      ),
    ),
    HttpApiEndpoint.get("log", "/households/:id/log", {
      params: ids,
      success: Schema.Array(LogEntry),
      error: wire(HouseholdNotFound),
    }).annotateMerge(note("The change log of the open periods (F37)")),
    HttpApiEndpoint.post("undo", "/log/:id/undo", {
      params: ids,
      error: [
        wire(LogEntryNotFound),
        wire(Forbidden),
        wire(CannotUndo),
        wire(PlanBelowSpent),
        wire(NotEnoughMoney),
        wire(NotEnoughInPeriod),
        wire(PlanTooSmall),
      ],
    }).annotateMerge(
      note(
        "Undo a change",
        "By somebody who may make that change. Refused when undoing it breaks a rule.",
      ),
    ),
  )
  .middleware(Authenticated)
  .annotateMerge(OpenApi.annotations({ title: "Households" })) {}

export class MembersApi extends HttpApiGroup.make("members")
  .add(
    HttpApiEndpoint.get("list", "/households/:id/members", {
      params: ids,
      success: Schema.Array(Member),
      error: wire(HouseholdNotFound),
    }).annotateMerge(note("The members, with their share (F14)")),
    HttpApiEndpoint.put("setRole", "/households/:id/members/:userId", {
      params: { id: Uuid, userId: UserId },
      payload: SetRole,
      success: Member,
      error: [
        wire(HouseholdNotFound),
        wire(Forbidden),
        wire(MemberNotFound),
        wire(LastOwner),
      ],
    }).annotateMerge(
      note(
        "Give or take the owner role (F22)",
        "Owners only; there is always at least one owner.",
      ),
    ),
    HttpApiEndpoint.delete("remove", "/households/:id/members/:userId", {
      params: { id: Uuid, userId: UserId },
      error: [
        wire(HouseholdNotFound),
        wire(Forbidden),
        wire(MemberNotFound),
        wire(LastOwner),
        wire(NegativeShare),
      ],
    }).annotateMerge(
      note(
        "Remove a member",
        "Owners only. Not with a negative share (freeze them instead); a positive share goes back to their wallet.",
      ),
    ),
    HttpApiEndpoint.post("freeze", "/households/:id/members/:userId/freeze", {
      params: { id: Uuid, userId: UserId },
      success: Member,
      error: [wire(HouseholdNotFound), wire(Forbidden), wire(MemberNotFound)],
    }).annotateMerge(
      note(
        "Freeze a member (F36)",
        "Owners only. A frozen member cannot spend and is removed once their share is no longer negative.",
      ),
    ),
    HttpApiEndpoint.post(
      "unfreeze",
      "/households/:id/members/:userId/unfreeze",
      {
        params: { id: Uuid, userId: UserId },
        success: Member,
        error: [wire(HouseholdNotFound), wire(Forbidden), wire(MemberNotFound)],
      },
    ).annotateMerge(note("Unfreeze a member")),
    HttpApiEndpoint.post("leave", "/households/:id/leave", {
      params: ids,
      payload: Leave,
      error: [wire(HouseholdNotFound), wire(LastOwner), wire(NegativeShare)],
    }).annotateMerge(
      note(
        "Leave a household (F36)",
        "Not with a negative share. The last owner first gives the role to somebody; the last member deletes the household.",
      ),
    ),
    HttpApiEndpoint.post("invite", "/households/:id/invitations", {
      params: ids,
      payload: Invite,
      success: Invitation.pipe(HttpApiSchema.status(201)),
      error: [
        wire(HouseholdNotFound),
        wire(Forbidden),
        wire(AlreadyMember),
        wire(LimitReached),
      ],
    }).annotateMerge(
      note(
        "Invite somebody by e-mail (F13)",
        "Owners only. Valid 7 days; inviting the address again renews it.",
      ),
    ),
    HttpApiEndpoint.get("invitations", "/households/:id/invitations", {
      params: ids,
      success: Schema.Array(Invitation),
      error: [wire(HouseholdNotFound), wire(Forbidden)],
    }).annotateMerge(note("Open invitations of a household", "Owners only.")),
    HttpApiEndpoint.delete(
      "revoke",
      "/households/:id/invitations/:invitationId",
      {
        params: { id: Uuid, invitationId: Uuid },
        error: [
          wire(HouseholdNotFound),
          wire(Forbidden),
          wire(InvitationNotFound),
        ],
      },
    ).annotateMerge(note("Revoke an invitation", "Owners only.")),
    HttpApiEndpoint.get("mine", "/invitations", {
      success: Schema.Array(Invitation),
    }).annotateMerge(note("Invitations for my address")),
    HttpApiEndpoint.post("accept", "/invitations/:id/accept", {
      params: ids,
      success: Household,
      error: [wire(InvitationNotFound), wire(LimitReached)],
    }).annotateMerge(
      note("Accept an invitation", "The user becomes a member at once."),
    ),
    HttpApiEndpoint.post("decline", "/invitations/:id/decline", {
      params: ids,
      error: wire(InvitationNotFound),
    }).annotateMerge(note("Decline an invitation")),
  )
  .middleware(Authenticated)
  .annotateMerge(OpenApi.annotations({ title: "Members" })) {}

export class EnvelopesApi extends HttpApiGroup.make("envelopes")
  .add(
    HttpApiEndpoint.get("list", "/households/:id/envelopes", {
      params: ids,
      success: Schema.Array(Envelope),
      error: wire(HouseholdNotFound),
    }).annotateMerge(note("Envelopes of a household, archived ones too")),
    HttpApiEndpoint.post("create", "/households/:id/envelopes", {
      params: ids,
      payload: SaveEnvelope,
      success: Envelope.pipe(HttpApiSchema.status(201)),
      error: [wire(HouseholdNotFound), wire(DuplicateEnvelopeName)],
    }).annotateMerge(note("Add an envelope (F12)", "Any member.")),
    HttpApiEndpoint.put("update", "/envelopes/:id", {
      params: ids,
      payload: SaveEnvelope,
      success: Envelope,
      error: [wire(EnvelopeNotFound), wire(DuplicateEnvelopeName)],
    }).annotateMerge(note("Rename or recolour an envelope")),
    HttpApiEndpoint.delete("delete", "/envelopes/:id", {
      params: ids,
      error: [
        wire(EnvelopeNotFound),
        wire(EnvelopeHasExpenses),
        wire(LastEnvelope),
      ],
    }).annotateMerge(
      note(
        "Delete an envelope",
        "Only one without expenses; archive the others.",
      ),
    ),
    HttpApiEndpoint.post("archive", "/envelopes/:id/archive", {
      params: ids,
      success: Envelope,
      error: [wire(EnvelopeNotFound), wire(LastEnvelope)],
    }).annotateMerge(
      note(
        "Archive an envelope",
        "Its expenses stay; its plans in the open periods drop to what was spent.",
      ),
    ),
    HttpApiEndpoint.post("unarchive", "/envelopes/:id/unarchive", {
      params: ids,
      success: Envelope,
      error: wire(EnvelopeNotFound),
    }).annotateMerge(note("Bring an envelope back")),
    HttpApiEndpoint.put("setPlan", "/periods/:id/plans/:envelopeId", {
      params: { id: Uuid, envelopeId: Uuid },
      payload: SetPlan,
      success: PeriodSummary,
      error: [
        wire(PeriodNotFound),
        wire(EnvelopeNotFound),
        wire(PeriodClosed),
        wire(PlanBelowSpent),
      ],
    }).annotateMerge(
      note(
        "Set the plan of an envelope in an open period (F19)",
        "Any member. Not below what was spent. The sum of plans may exceed the balance; the summary says so.",
      ),
    ),
  )
  .middleware(Authenticated)
  .annotateMerge(OpenApi.annotations({ title: "Envelopes" })) {}

export class ExpensesApi extends HttpApiGroup.make("expenses")
  .add(
    HttpApiEndpoint.post("create", "/households/:id/expenses", {
      params: ids,
      payload: SaveExpense,
      success: ExpenseResult.pipe(HttpApiSchema.status(201)),
      error: [wire(HouseholdNotFound), ...expenseErrors, wire(Forbidden)],
    }).annotateMerge(
      note(
        "Add an expense (F08)",
        "It has to fit the plan of the envelope and the balance of the current period. A plan that is too small grows by itself out of free money; otherwise 409 PlanTooSmall or NotEnoughInPeriod say what to bring from the wallet, and WalletWouldGoNegative asks to confirm a minus. Send the `decision` to go ahead.",
      ),
    ),
    HttpApiEndpoint.get("get", "/expenses/:id", {
      params: ids,
      success: Expense,
      error: wire(ExpenseNotFound),
    }).annotateMerge(note("Get an expense")),
    HttpApiEndpoint.put("update", "/expenses/:id", {
      params: ids,
      payload: SaveExpense,
      success: ExpenseResult,
      error: [wire(ExpenseNotFound), wire(Forbidden), ...expenseErrors],
    }).annotateMerge(
      note(
        "Edit an expense (F09)",
        "Its author, or an owner. In an open period through the steps of F08; in a closed one only the title.",
      ),
    ),
    HttpApiEndpoint.delete("delete", "/expenses/:id", {
      params: ids,
      error: [wire(ExpenseNotFound), wire(Forbidden), wire(PeriodClosed)],
    }).annotateMerge(
      note("Delete an expense", "The money goes back to the piggy bank."),
    ),
    HttpApiEndpoint.get("list", "/expenses", {
      query: {
        householdId: Schema.optional(Uuid),
        periodId: Schema.optional(Uuid),
        envelopeId: Schema.optional(Uuid),
        authorId: Schema.optional(UserId),
        /** A member's id, `shared` or `none`. */
        forWhom: Schema.optional(Schema.String),
        /** Inclusive day in the household's time zone. */
        from: Schema.optional(IsoDate),
        to: Schema.optional(IsoDate),
        ...page,
      },
      success: Schema.Array(Expense),
    }).annotateMerge(
      note(
        "Expense history (F10)",
        "Of the user's households, newest first. 50 rows unless `limit` says otherwise (at most 200).",
      ),
    ),
  )
  .middleware(Authenticated)
  .annotateMerge(OpenApi.annotations({ title: "Expenses" })) {}

export class WalletApi extends HttpApiGroup.make("wallet")
  .add(
    HttpApiEndpoint.get("get", "/wallet", { success: Wallet }).annotateMerge(
      note("My wallet (F31)", "wpływy − przelewy + wycofania, as of now."),
    ),
    HttpApiEndpoint.get("entries", "/wallet/entries", {
      query: { ...page },
      success: Schema.Array(WalletEntry),
    }).annotateMerge(
      note("Wallet history: incomes, transfers, withdrawals, newest first"),
    ),
    HttpApiEndpoint.post("addIncome", "/wallet/incomes", {
      payload: CreateIncome,
      success: WalletEntry.pipe(HttpApiSchema.status(201)),
    }).annotateMerge(note("Add an income, certain or estimated")),
    HttpApiEndpoint.put("updateIncome", "/wallet/incomes/:id", {
      params: ids,
      payload: UpdateIncome,
      success: WalletEntry,
      error: [
        wire(IncomeNotFound),
        wire(WalletWouldGoNegative),
        wire(NotEnoughMoney),
        wire(PeriodNotFound),
        wire(PeriodClosed),
      ],
    }).annotateMerge(
      note(
        "Correct an income",
        "Down below zero only with the `correction`: keep the minus, or take the missing amount back from a period first.",
      ),
    ),
    HttpApiEndpoint.post("confirmIncome", "/wallet/incomes/:id/confirm", {
      params: ids,
      payload: ConfirmIncome,
      success: WalletEntry,
      error: [
        wire(IncomeNotFound),
        wire(WalletWouldGoNegative),
        wire(NotEnoughMoney),
        wire(PeriodNotFound),
        wire(PeriodClosed),
      ],
    }).annotateMerge(note("Confirm the real amount of an estimated income")),
    HttpApiEndpoint.post("removeIncome", "/wallet/incomes/:id/remove", {
      params: ids,
      payload: RemoveIncome,
      error: [
        wire(IncomeNotFound),
        wire(WalletWouldGoNegative),
        wire(NotEnoughMoney),
        wire(PeriodNotFound),
        wire(PeriodClosed),
      ],
    }).annotateMerge(note("Delete an income (a correction down)")),
  )
  .middleware(Authenticated)
  .annotateMerge(OpenApi.annotations({ title: "Wallet" })) {}

export class RecurringApi extends HttpApiGroup.make("recurring")
  .add(
    HttpApiEndpoint.get("list", "/recurring-rules", {
      success: Schema.Array(RecurringRule),
    }).annotateMerge(
      note(
        "Recurring rules",
        "The user's incomes and transfers, and the expense rules of their households.",
      ),
    ),
    HttpApiEndpoint.post("create", "/recurring-rules", {
      payload: SaveRule,
      success: RecurringRule.pipe(HttpApiSchema.status(201)),
      error: [
        wire(HouseholdNotFound),
        wire(EnvelopeNotFound),
        wire(InvalidSchedule),
      ],
    }).annotateMerge(note("Add a recurring rule (F25, F26, F27)")),
    HttpApiEndpoint.put("update", "/recurring-rules/:id", {
      params: ids,
      payload: SaveRule,
      success: RecurringRule,
      error: [
        wire(RuleNotFound),
        wire(Forbidden),
        wire(HouseholdNotFound),
        wire(EnvelopeNotFound),
        wire(InvalidSchedule),
      ],
    }).annotateMerge(
      note("Edit a rule", "Expense rules: their author or an owner."),
    ),
    HttpApiEndpoint.delete("delete", "/recurring-rules/:id", {
      params: ids,
      error: [wire(RuleNotFound), wire(Forbidden)],
    }).annotateMerge(note("Delete a rule", "What it made stays.")),
    HttpApiEndpoint.post("apply", "/recurring-rules/:id/apply", {
      params: ids,
      payload: ApplyRule,
      success: ApplyResult,
      error: [wire(RuleNotFound), wire(Forbidden)],
    }).annotateMerge(
      note(
        "Apply a rule early",
        "Its next occurrence: an income (an estimated one with the real amount), or an expense in the current period.",
      ),
    ),
    HttpApiEndpoint.post("applyAll", "/households/:id/recurring-rules/apply", {
      params: ids,
      success: ApplyResult,
      error: wire(HouseholdNotFound),
    }).annotateMerge(
      note(
        "Apply every expense rule of a household early",
        "Their occurrences left in the current period.",
      ),
    ),
  )
  .middleware(Authenticated)
  .annotateMerge(OpenApi.annotations({ title: "Recurring" })) {}

export class AccountApi extends HttpApiGroup.make("account")
  .add(
    HttpApiEndpoint.put("update", "/account", {
      payload: UpdateProfile,
      success: UserJson,
    }).annotateMerge(note("Set my name")),
    HttpApiEndpoint.post("delete", "/account/delete", {
      payload: DeleteAccount,
      error: [wire(ConfirmationMismatch), wire(NegativeShare)],
    }).annotateMerge(
      note(
        "Delete my account (F04)",
        "Type the address of the account to confirm. Not while the user has a negative share. The wallet, its incomes and the user's rules go; positive shares stay in the piggy banks as nobody's money; households where the user is alone go too.",
      ),
    ),
  )
  .middleware(Authenticated)
  .annotateMerge(OpenApi.annotations({ title: "Account" })) {}
