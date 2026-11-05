// The app's own terms for the money model of SWS v0.5 (docs/MONEY_MODEL.md).
// Amounts are in grosze, as the API sends them; screens format them with
// `formatMinor`.

/// `owner` manages members, invitations, the period and deleting; `member`
/// transfers, plans and spends.
enum Role { owner, member }

enum CycleKind { monthly, weeks, manual }

/// How a household cuts time into periods.
class Cycle {
  const Cycle({required this.kind, this.day, this.weeks, this.anchorOn});

  /// Monthly from the 1st, the default.
  const Cycle.monthly([int this.day = 1])
    : kind = CycleKind.monthly,
      weeks = null,
      anchorOn = null;

  final CycleKind kind;

  /// Monthly: the day a period starts on (1-31).
  final int? day;

  /// Every this many weeks, from [anchorOn].
  final int? weeks;
  final DateTime? anchorOn;
}

enum PeriodStatus { current, next, closed }

/// Both days are included, in the time zone of the household.
class Period {
  const Period({
    required this.id,
    required this.householdId,
    required this.startsOn,
    required this.endsOn,
    required this.status,
  });

  final String id;
  final String householdId;
  final DateTime startsOn;
  final DateTime endsOn;
  final PeriodStatus status;

  bool get isOpen => status != PeriodStatus.closed;
}

class Household {
  const Household({
    required this.id,
    required this.name,
    required this.timeZone,
    required this.cycle,
    required this.role,
    required this.frozen,
    required this.memberCount,
    required this.current,
    required this.next,
    required this.balanceMinor,
  });

  final String id;
  final String name;
  final String timeZone;
  final Cycle cycle;

  /// The role of the signed-in user.
  final Role role;

  /// The signed-in user is frozen here: they cannot spend.
  final bool frozen;
  final int memberCount;
  final Period current;
  final Period? next;

  /// Of the current piggy bank.
  final int balanceMinor;

  bool get isOwner => role == Role.owner;
}

class Member {
  const Member({
    required this.userId,
    required this.email,
    required this.name,
    required this.role,
    required this.frozen,
    required this.shareMinor,
  });

  final String userId;
  final String email;
  final String? name;
  final Role role;
  final bool frozen;

  /// In the current piggy bank; negative: spent more than put in.
  final int shareMinor;

  String get displayName => name ?? email;
}

class Invitation {
  const Invitation({
    required this.id,
    required this.householdId,
    required this.householdName,
    required this.email,
    required this.invitedBy,
    required this.expiresAt,
  });

  final String id;
  final String householdId;
  final String householdName;
  final String email;
  final String? invitedBy;
  final DateTime expiresAt;
}

// ---- envelopes and the piggy bank ---------------------------------------------

class Envelope {
  const Envelope({
    required this.id,
    required this.householdId,
    required this.name,
    required this.color,
    required this.icon,
    required this.archived,
  });

  final String id;
  final String householdId;
  final String name;
  final String color;
  final String? icon;
  final bool archived;
}

/// An envelope in one period: its plan (manual + recurring part), what was
/// spent and what is left.
class EnvelopeFigures {
  const EnvelopeFigures({
    required this.envelopeId,
    required this.name,
    required this.color,
    required this.icon,
    required this.archived,
    required this.planMinor,
    required this.manualMinor,
    required this.recurringMinor,
    required this.spentMinor,
    required this.leftMinor,
    required this.sharePercent,
    required this.previousSpentMinor,
  });

  final String envelopeId;
  final String name;
  final String color;
  final String? icon;
  final bool archived;
  final int planMinor;
  final int manualMinor;
  final int recurringMinor;
  final int spentMinor;
  final int leftMinor;
  final double sharePercent;
  final int? previousSpentMinor;

  /// How much of the plan is spent, 0-1 (more when overspent).
  double get fraction =>
      planMinor <= 0 ? (spentMinor > 0 ? 1 : 0) : spentMinor / planMinor;

  Envelope get envelope => Envelope(
    id: envelopeId,
    householdId: '',
    name: name,
    color: color,
    icon: icon,
    archived: archived,
  );
}

/// Who has how much in a piggy bank (F33).
class ShareFigures {
  const ShareFigures({
    required this.userId,
    required this.name,
    required this.member,
    required this.transfersMinor,
    required this.withdrawalsMinor,
    required this.spentMinor,
    required this.fromNobodyMinor,
    required this.shareMinor,
  });

  final String? userId;
  final String name;
  final bool member;
  final int transfersMinor;
  final int withdrawalsMinor;
  final int spentMinor;
  final int fromNobodyMinor;
  final int shareMinor;
}

class Forecast {
  const Forecast({
    required this.variableMinor,
    required this.recurringMinor,
    required this.projectedSpentMinor,
    required this.projectedBalanceMinor,
  });

  final int variableMinor;
  final int recurringMinor;
  final int projectedSpentMinor;
  final int projectedBalanceMinor;
}

/// One piggy bank: przelewy − wycofania + niewydane z poprzedniego okresu −
/// wydatki, with the plans and the shares.
class PeriodSummary {
  const PeriodSummary({
    required this.period,
    required this.transfersMinor,
    required this.withdrawalsMinor,
    required this.carryInMinor,
    required this.spentMinor,
    required this.estimatedSpentMinor,
    required this.balanceMinor,
    required this.plansTotalMinor,
    required this.freeMinor,
    required this.plansExceedBalance,
    required this.carryOutMinor,
    required this.nobodyLeftMinor,
    required this.envelopes,
    required this.shares,
    required this.forecast,
  });

  final Period period;
  final int transfersMinor;
  final int withdrawalsMinor;
  final int carryInMinor;
  final int spentMinor;
  final int estimatedSpentMinor;
  final int balanceMinor;
  final int plansTotalMinor;

  /// What no plan holds yet; negative: the plans exceed the balance.
  final int freeMinor;
  final bool plansExceedBalance;
  final int? carryOutMinor;
  final int nobodyLeftMinor;
  final List<EnvelopeFigures> envelopes;
  final List<ShareFigures> shares;
  final Forecast? forecast;
}

/// The happy event after a period closed (F35).
class ClosedSummary {
  const ClosedSummary({
    required this.periodId,
    required this.householdId,
    required this.householdName,
    required this.startsOn,
    required this.endsOn,
    required this.transfersMinor,
    required this.carryInMinor,
    required this.spentMinor,
    required this.carryOutMinor,
  });

  final String periodId;
  final String householdId;
  final String householdName;
  final DateTime startsOn;
  final DateTime endsOn;
  final int transfersMinor;
  final int carryInMinor;
  final int spentMinor;
  final int carryOutMinor;
}

// ---- money moving ---------------------------------------------------------------

enum MoveKind { transfer, withdrawal, carry, forfeit }

class Move {
  const Move({
    required this.id,
    required this.kind,
    required this.userName,
    required this.amountMinor,
    required this.madeAt,
  });

  final String id;
  final MoveKind kind;
  final String? userName;
  final int amountMinor;
  final DateTime madeAt;
}

/// What a transfer or withdrawal leaves behind.
class MoveOutcome {
  const MoveOutcome({
    required this.walletMinor,
    required this.usedUnconfirmed,
    required this.plansExceedBalance,
  });

  final int walletMinor;
  final bool usedUnconfirmed;
  final bool plansExceedBalance;
}

class Wallet {
  const Wallet({required this.balanceMinor, required this.unconfirmedMinor});

  final int balanceMinor;

  /// "w tym niepotwierdzone"
  final int unconfirmedMinor;

  bool get negative => balanceMinor < 0;
}

enum WalletEntryKind { income, transfer, withdrawal, giveBack }

class WalletEntry {
  const WalletEntry({
    required this.id,
    required this.kind,
    required this.amountMinor,
    required this.onDate,
    required this.note,
    required this.estimated,
    required this.householdName,
    required this.ruleId,
  });

  final String id;
  final WalletEntryKind kind;
  final int amountMinor;
  final DateTime onDate;
  final String? note;
  final bool estimated;
  final String? householdName;
  final String? ruleId;

  /// Money in (an income, a withdrawal, a share given back).
  bool get isIn => kind != WalletEntryKind.transfer;
}

/// When an income corrected down would put the wallet below zero: keep the
/// minus, or first take the missing amount back from a period.
class Correction {
  const Correction.keepMinus()
    : allowNegative = true,
      withdrawFromPeriodId = null;
  const Correction.withdrawFrom(String this.withdrawFromPeriodId)
    : allowNegative = false;

  final bool allowNegative;
  final String? withdrawFromPeriodId;
}

// ---- expenses ----------------------------------------------------------------------

enum ForWhom { member, shared }

class Expense {
  const Expense({
    required this.id,
    required this.householdId,
    required this.periodId,
    required this.envelopeId,
    required this.createdBy,
    required this.authorName,
    required this.amountMinor,
    required this.spentAt,
    required this.title,
    required this.forWhom,
    required this.forWhomUserId,
    required this.forWhomName,
    required this.estimated,
    required this.ruleId,
  });

  final String id;
  final String householdId;
  final String periodId;
  final String envelopeId;
  final String? createdBy;
  final String authorName;
  final int amountMinor;
  final DateTime spentAt;
  final String? title;
  final ForWhom? forWhom;
  final String? forWhomUserId;
  final String? forWhomName;
  final bool estimated;
  final String? ruleId;
}

/// What a new or changed expense is.
class ExpenseDraft {
  const ExpenseDraft({
    required this.envelopeId,
    required this.amountMinor,
    required this.spentAt,
    this.title,
    this.forWhom,
    this.forWhomUserId,
  });

  final String envelopeId;
  final int amountMinor;
  final DateTime spentAt;
  final String? title;
  final ForWhom? forWhom;
  final String? forWhomUserId;
}

/// What the user decided after the server said the expense does not fit
/// (F08): raise the plan, bring money from the wallet, let it go below zero.
class Decision {
  const Decision({
    this.raisePlan = false,
    this.transferMinor = 0,
    this.allowNegativeWallet = false,
  });

  final bool raisePlan;
  final int transferMinor;
  final bool allowNegativeWallet;

  Decision copyWith({bool? allowNegativeWallet}) => Decision(
    raisePlan: raisePlan,
    transferMinor: transferMinor,
    allowNegativeWallet: allowNegativeWallet ?? this.allowNegativeWallet,
  );
}

class ExpenseOutcome {
  const ExpenseOutcome({
    required this.expense,
    required this.transferredMinor,
    required this.raisedPlanMinor,
    required this.plansExceedBalance,
  });

  final Expense expense;
  final int transferredMinor;
  final int raisedPlanMinor;
  final bool plansExceedBalance;
}

// ---- recurring rules ---------------------------------------------------------------

enum RuleKind { income, transfer, expense }

enum RuleFrequency { monthly, weeks }

class RecurringRule {
  const RecurringRule({
    this.id,
    required this.kind,
    this.userId,
    this.householdId,
    this.envelopeId,
    required this.name,
    required this.amountMinor,
    this.estimated = false,
    this.frequency = RuleFrequency.monthly,
    this.dayOfMonth,
    this.everyWeeks,
    this.anchorOn,
    this.startsOn,
    this.toNextPeriod = false,
    this.active = true,
  });

  final String? id;
  final RuleKind kind;

  /// Who made it: the owner of the wallet, the author of the expenses.
  final String? userId;
  final String? householdId;
  final String? envelopeId;
  final String name;
  final int amountMinor;
  final bool estimated;
  final RuleFrequency frequency;
  final int? dayOfMonth;
  final int? everyWeeks;
  final DateTime? anchorOn;
  final DateTime? startsOn;

  /// A transfer goes to the period after the one of its day.
  final bool toNextPeriod;
  final bool active;

  RecurringRule copyWith({bool? active}) => RecurringRule(
    id: id,
    kind: kind,
    userId: userId,
    householdId: householdId,
    envelopeId: envelopeId,
    name: name,
    amountMinor: amountMinor,
    estimated: estimated,
    frequency: frequency,
    dayOfMonth: dayOfMonth,
    everyWeeks: everyWeeks,
    anchorOn: anchorOn,
    startsOn: startsOn,
    toNextPeriod: toNextPeriod,
    active: active ?? this.active,
  );
}

// ---- the to-do list, the app start, the log ---------------------------------------------

enum TodoKind {
  incomeEstimate,
  transferNoMoney,
  expenseNotFit,
  expenseEstimate,
  expenseMissed,
}

class TodoItem {
  const TodoItem({
    required this.id,
    required this.kind,
    required this.householdId,
    required this.householdName,
    required this.periodId,
    required this.refId,
    required this.envelopeId,
    required this.occurrenceOn,
    required this.amountMinor,
    required this.title,
  });

  final String id;
  final TodoKind kind;
  final String? householdId;
  final String? householdName;
  final String? periodId;
  final String? refId;
  final String? envelopeId;
  final DateTime? occurrenceOn;
  final int amountMinor;
  final String? title;

  /// An expense waits: it goes through the steps of F08 when resolved.
  bool get isExpense =>
      kind == TodoKind.expenseNotFit ||
      kind == TodoKind.expenseMissed ||
      kind == TodoKind.expenseEstimate;
}

class SyncOutcome {
  const SyncOutcome({required this.todo, required this.summaries});

  final int todo;
  final List<ClosedSummary> summaries;
}

class LogEntry {
  const LogEntry({
    required this.id,
    required this.userName,
    required this.action,
    required this.summary,
    required this.createdAt,
    required this.undone,
    required this.canUndo,
  });

  final String id;
  final String userName;
  final String action;
  final String summary;
  final DateTime createdAt;
  final bool undone;
  final bool canUndo;
}

/// A household on the dashboard: its current piggy bank and what was spent
/// in the range the dashboard shows (F38).
class HouseholdOverview {
  const HouseholdOverview({
    required this.id,
    required this.name,
    required this.current,
    required this.balanceMinor,
    required this.freeMinor,
    required this.spentMinor,
  });

  final String id;
  final String name;
  final Period current;
  final int balanceMinor;
  final int freeMinor;
  final int spentMinor;
}

class Overview {
  const Overview({
    required this.wallet,
    required this.households,
    required this.todo,
  });

  final Wallet wallet;
  final List<HouseholdOverview> households;
  final int todo;
}
