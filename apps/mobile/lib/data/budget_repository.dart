import 'package:bida_api_client/bida_api_client.dart' as api;
import 'package:dio/dio.dart';

import '../models/models.dart';
import 'api_exception.dart';

/// Single entry point to the backend, in the app's own terms. Every method
/// either returns app models or throws an [ApiException]. The money rules
/// (balances, shares, the steps of F08) are the server's: the app shows what
/// it says and sends back what the user decided.
class BudgetRepository {
  BudgetRepository(Dio dio) : _api = api.BidaApi(dio);

  final api.BidaApi _api;

  // ------------------------------------------------------------- the app start

  /// What is due: closing and opening periods, then the recurring incomes,
  /// transfers and expenses. Run on every start; doing it again does nothing
  /// twice.
  Future<SyncOutcome> sync() => guard(() async {
    final r = await _api.sync.syncRun();
    return SyncOutcome(
      todo: r.todo,
      summaries: r.summaries.map(_closedSummary).toList(),
    );
  });

  Future<Overview> overview(DateTime from, DateTime to) => guard(() async {
    final o = await _api.sync.syncOverview(
      from: formatDay(from),
      to: formatDay(to),
    );
    return Overview(
      wallet: _wallet(o.wallet),
      households: [
        for (final h in o.households)
          HouseholdOverview(
            id: h.id,
            name: h.name,
            current: _period(h.current),
            balanceMinor: h.balanceMinor,
            freeMinor: h.freeMinor,
            spentMinor: h.spentMinor,
          ),
      ],
      todo: o.todo,
    );
  });

  Future<List<ClosedSummary>> summaries() => guard(
    () async => (await _api.sync.syncSummaries()).map(_closedSummary).toList(),
  );

  Future<void> markSummarySeen(String periodId) =>
      guard(() => _api.sync.syncSeen(id: periodId));

  Future<List<TodoItem>> todo() =>
      guard(() async => (await _api.sync.syncTodo()).map(_todo).toList());

  Future<void> resolveTodo(
    String id, {
    required int amountMinor,
    Decision? decision,
    Correction? correction,
  }) => guard(
    () => _api.sync.syncResolve(
      id: id,
      body: api.ResolveTodo(
        amountMinor: amountMinor,
        decision: decision == null ? null : _decision(decision),
        correction: correction == null ? null : _correction(correction),
      ),
    ),
  );

  Future<void> dismissTodo(String id) =>
      guard(() => _api.sync.syncDismiss(id: id));

  // ------------------------------------------------------------------ wallet

  Future<Wallet> wallet() =>
      guard(() async => _wallet(await _api.wallet.walletGet()));

  Future<List<WalletEntry>> walletEntries({int limit = 100}) => guard(
    () async => (await _api.wallet.walletEntries(
      limit: '$limit',
    )).map(_walletEntry).toList(),
  );

  Future<void> addIncome({
    required int amountMinor,
    required DateTime onDate,
    String? note,
    bool estimated = false,
  }) => guard(
    () => _api.wallet.walletAddIncome(
      body: api.CreateIncome(
        amountMinor: amountMinor,
        onDate: formatDay(onDate),
        note: note,
        estimated: estimated,
      ),
    ),
  );

  Future<void> updateIncome(
    WalletEntry income, {
    required int amountMinor,
    required DateTime onDate,
    String? note,
    required bool estimated,
    Correction? correction,
  }) => guard(
    () => _api.wallet.walletUpdateIncome(
      id: income.id,
      body: api.UpdateIncome(
        amountMinor: amountMinor,
        onDate: formatDay(onDate),
        note: note,
        estimated: estimated,
        correction: correction == null ? null : _correction(correction),
      ),
    ),
  );

  Future<void> confirmIncome(
    String id,
    int amountMinor, {
    Correction? correction,
  }) => guard(
    () => _api.wallet.walletConfirmIncome(
      id: id,
      body: api.ConfirmIncome(
        amountMinor: amountMinor,
        correction: correction == null ? null : _correction(correction),
      ),
    ),
  );

  Future<void> removeIncome(String id, {Correction? correction}) => guard(
    () => _api.wallet.walletRemoveIncome(
      id: id,
      body: api.RemoveIncome(
        correction: correction == null ? null : _correction(correction),
      ),
    ),
  );

  /// From the wallet into a period (the current or the next one).
  Future<MoveOutcome> transfer(String periodId, int amountMinor) =>
      guard(() async {
        final r = await _api.households.householdsTransfer(
          id: periodId,
          body: api.MoveMoney(amountMinor: amountMinor),
        );
        return _moveOutcome(r);
      });

  /// Back to the wallet: at most the share, at most what is there.
  Future<MoveOutcome> withdraw(String periodId, int amountMinor) =>
      guard(() async {
        final r = await _api.households.householdsWithdraw(
          id: periodId,
          body: api.MoveMoney(amountMinor: amountMinor),
        );
        return _moveOutcome(r);
      });

  // -------------------------------------------------------------- households

  Future<List<Household>> households() => guard(
    () async =>
        (await _api.households.householdsList()).map(_household).toList(),
  );

  Future<Household> household(String id) => guard(
    () async => _household(await _api.households.householdsGet(id: id)),
  );

  Future<Household> createHousehold({
    required String name,
    Cycle? cycle,
    DateTime? firstEndsOn,
    List<String>? envelopes,
  }) => guard(
    () async => _household(
      await _api.households.householdsCreate(
        body: api.CreateHousehold(
          name: name,
          cycle: cycle == null ? null : _cycleOf(cycle),
          firstEndsOn: firstEndsOn == null ? null : formatDay(firstEndsOn),
          timeZone: null,
          envelopes: envelopes,
        ),
      ),
    ),
  );

  Future<void> renameHousehold(String id, String name) => guard(
    () => _api.households.householdsRename(
      id: id,
      body: api.RenameHousehold(name: name),
    ),
  );

  Future<void> deleteHousehold(String id) =>
      guard(() => _api.households.householdsDelete(id: id));

  Future<void> setCycle(String id, Cycle cycle) => guard(
    () => _api.households.householdsSetCycle(
      id: id,
      body: api.SetCycle(cycle: _cycleOf(cycle)),
    ),
  );

  /// Newest first.
  Future<List<Period>> periods(String householdId) => guard(
    () async => (await _api.households.householdsPeriods(
      id: householdId,
    )).map(_period).toList(),
  );

  Future<Period> openNextPeriod(String householdId) => guard(
    () async =>
        _period(await _api.households.householdsOpenNext(id: householdId)),
  );

  Future<void> setPeriodEnd(String periodId, DateTime endsOn) => guard(
    () => _api.households.householdsSetEnd(
      id: periodId,
      body: api.SetPeriodEnd(endsOn: formatDay(endsOn)),
    ),
  );

  /// [forWhom]: a member's id, `shared` or `none`.
  Future<PeriodSummary> periodSummary(String periodId, {String? forWhom}) =>
      guard(
        () async => _summary(
          await _api.households.householdsPeriod(
            id: periodId,
            forWhom: forWhom,
          ),
        ),
      );

  Future<List<Move>> moves(String periodId) => guard(
    () async => (await _api.households.householdsMoves(id: periodId))
        .map(
          (m) => Move(
            id: m.id,
            kind: switch (m.kind) {
              api.MoveKind.withdrawal => MoveKind.withdrawal,
              api.MoveKind.carry => MoveKind.carry,
              api.MoveKind.forfeit => MoveKind.forfeit,
              _ => MoveKind.transfer,
            },
            userName: m.userName,
            amountMinor: m.amountMinor,
            madeAt: DateTime.parse(m.madeAt).toLocal(),
          ),
        )
        .toList(),
  );

  Future<List<LogEntry>> log(String householdId) => guard(
    () async => (await _api.households.householdsLog(id: householdId))
        .map(
          (e) => LogEntry(
            id: e.id,
            userName: e.userName,
            action: e.action,
            summary: e.summary,
            createdAt: DateTime.parse(e.createdAt).toLocal(),
            undone: e.undone,
            canUndo: e.canUndo,
          ),
        )
        .toList(),
  );

  Future<void> undo(String logEntryId) =>
      guard(() => _api.households.householdsUndo(id: logEntryId));

  // ------------------------------------------------------- members, invitations

  Future<List<Member>> members(String householdId) => guard(
    () async =>
        (await _api.members.membersList(id: householdId)).map(_member).toList(),
  );

  Future<void> setRole(String householdId, String userId, Role role) => guard(
    () => _api.members.membersSetRole(
      id: householdId,
      userId: userId,
      body: api.SetRole(role: _roleOf(role)),
    ),
  );

  Future<void> removeMember(String householdId, String userId) =>
      guard(() => _api.members.membersRemove(id: householdId, userId: userId));

  Future<void> setFrozen(String householdId, String userId, bool frozen) =>
      guard(
        () => frozen
            ? _api.members.membersFreeze(id: householdId, userId: userId)
            : _api.members.membersUnfreeze(id: householdId, userId: userId),
      );

  /// [withdraw]: take the shares back to the wallet; otherwise they stay in
  /// the household as nobody's money.
  Future<void> leave(String householdId, {required bool withdraw}) => guard(
    () => _api.members.membersLeave(
      id: householdId,
      body: api.Leave(withdraw: withdraw),
    ),
  );

  Future<void> invite(String householdId, String email) => guard(
    () => _api.members.membersInvite(
      id: householdId,
      body: api.Invite(email: email, role: api.Role.member),
    ),
  );

  Future<List<Invitation>> householdInvitations(String householdId) => guard(
    () async => (await _api.members.membersInvitations(
      id: householdId,
    )).map(_invitation).toList(),
  );

  Future<void> revokeInvitation(String householdId, String invitationId) =>
      guard(
        () => _api.members.membersRevoke(
          id: householdId,
          invitationId: invitationId,
        ),
      );

  Future<List<Invitation>> myInvitations() => guard(
    () async => (await _api.members.membersMine()).map(_invitation).toList(),
  );

  Future<void> acceptInvitation(String id) =>
      guard(() => _api.members.membersAccept(id: id));

  Future<void> declineInvitation(String id) =>
      guard(() => _api.members.membersDecline(id: id));

  // ------------------------------------------------------------------ envelopes

  /// Archived ones too.
  Future<List<Envelope>> envelopes(String householdId) => guard(
    () async => (await _api.envelopes.envelopesList(id: householdId))
        .map(
          (e) => Envelope(
            id: e.id,
            householdId: e.householdId,
            name: e.name,
            color: e.color,
            icon: e.icon,
            archived: e.archived,
          ),
        )
        .toList(),
  );

  Future<void> createEnvelope(
    String householdId, {
    required String name,
    required String color,
    String? icon,
  }) => guard(
    () => _api.envelopes.envelopesCreate(
      id: householdId,
      body: api.SaveEnvelope(name: name, color: color, icon: icon),
    ),
  );

  Future<void> updateEnvelope(
    String id, {
    required String name,
    required String color,
    String? icon,
  }) => guard(
    () => _api.envelopes.envelopesUpdate(
      id: id,
      body: api.SaveEnvelope(name: name, color: color, icon: icon),
    ),
  );

  /// Throws `EnvelopeHasExpenses` for one with expenses: archive it instead.
  Future<void> deleteEnvelope(String id) =>
      guard(() => _api.envelopes.envelopesDelete(id: id));

  Future<void> setArchived(String id, bool archived) => guard(
    () => archived
        ? _api.envelopes.envelopesArchive(id: id)
        : _api.envelopes.envelopesUnarchive(id: id),
  );

  Future<PeriodSummary> setPlan(
    String periodId,
    String envelopeId,
    int amountMinor,
  ) => guard(
    () async => _summary(
      await _api.envelopes.envelopesSetPlan(
        id: periodId,
        envelopeId: envelopeId,
        body: api.SetPlan(amountMinor: amountMinor),
      ),
    ),
  );

  // ------------------------------------------------------------------- expenses

  /// Throws `PlanTooSmall`, `NotEnoughInPeriod` or `WalletWouldGoNegative`
  /// when the user has to decide; send the [decision] to go ahead.
  Future<ExpenseOutcome> addExpense(
    String householdId,
    ExpenseDraft draft, {
    Decision? decision,
  }) => guard(
    () async => _expenseOutcome(
      await _api.expenses.expensesCreate(
        id: householdId,
        body: _saveExpense(draft, decision),
      ),
    ),
  );

  Future<ExpenseOutcome> updateExpense(
    String id,
    ExpenseDraft draft, {
    Decision? decision,
  }) => guard(
    () async => _expenseOutcome(
      await _api.expenses.expensesUpdate(
        id: id,
        body: _saveExpense(draft, decision),
      ),
    ),
  );

  Future<void> deleteExpense(String id) =>
      guard(() => _api.expenses.expensesDelete(id: id));

  /// Newest first. [forWhom]: a member's id, `shared` or `none`.
  Future<List<Expense>> expenses({
    String? householdId,
    String? periodId,
    String? envelopeId,
    String? authorId,
    String? forWhom,
    int limit = 200,
  }) => guard(
    () async => (await _api.expenses.expensesList(
      householdId: householdId,
      periodId: periodId,
      envelopeId: envelopeId,
      authorId: authorId,
      forWhom: forWhom,
      limit: '$limit',
    )).map(_expense).toList(),
  );

  // ------------------------------------------------------------------ recurring

  Future<List<RecurringRule>> recurringRules() => guard(
    () async => (await _api.recurring.recurringList()).map(_rule).toList(),
  );

  Future<void> saveRule(RecurringRule rule) => guard(() async {
    final body = _saveRule(rule);
    if (rule.id == null) {
      await _api.recurring.recurringCreate(body: body);
    } else {
      await _api.recurring.recurringUpdate(id: rule.id!, body: body);
    }
  });

  Future<void> deleteRule(String id) =>
      guard(() => _api.recurring.recurringDelete(id: id));

  /// Its next occurrence now; [amountMinor] is the real amount of an estimate.
  /// Returns how many went to the to-do list instead.
  Future<int> applyRule(String id, {int? amountMinor}) => guard(
    () async => (await _api.recurring.recurringApply(
      id: id,
      body: api.ApplyRule(amountMinor: amountMinor),
    )).todo,
  );

  Future<void> applyAllRules(String householdId) =>
      guard(() => _api.recurring.recurringApplyAll(id: householdId));

  // -------------------------------------------------------------------- account

  Future<void> setName(String? name) => guard(
    () => _api.account.accountUpdate(body: api.UpdateProfile(name: name)),
  );

  /// Throws `NegativeShare` while the user owes a household.
  Future<void> deleteAccount(String email) => guard(
    () => _api.account.accountDelete(body: api.DeleteAccount(email: email)),
  );

  // -------------------------------------------------------------------- mapping

  static Wallet _wallet(api.Wallet w) => Wallet(
    balanceMinor: w.balanceMinor,
    unconfirmedMinor: w.unconfirmedMinor,
  );

  static Period _period(api.Period p) => Period(
    id: p.id,
    householdId: p.householdId,
    startsOn: parseDay(p.startsOn),
    endsOn: parseDay(p.endsOn),
    status: switch (p.status) {
      api.PeriodStatus.next => PeriodStatus.next,
      api.PeriodStatus.closed => PeriodStatus.closed,
      _ => PeriodStatus.current,
    },
  );

  static Cycle _cycle(api.Cycle c) => Cycle(
    kind: switch (c.kind) {
      api.CycleKind.weeks => CycleKind.weeks,
      api.CycleKind.manual => CycleKind.manual,
      _ => CycleKind.monthly,
    },
    day: c.day,
    weeks: c.weeks,
    anchorOn: c.anchorOn == null ? null : parseDay(c.anchorOn!),
  );

  static api.Cycle _cycleOf(Cycle c) => api.Cycle(
    kind: switch (c.kind) {
      CycleKind.monthly => api.CycleKind.monthly,
      CycleKind.weeks => api.CycleKind.weeks,
      CycleKind.manual => api.CycleKind.manual,
    },
    day: c.kind == CycleKind.monthly ? (c.day ?? 1) : null,
    weeks: c.kind == CycleKind.weeks ? (c.weeks ?? 1) : null,
    anchorOn: c.anchorOn == null ? null : formatDay(c.anchorOn!),
  );

  static Role _role(api.Role r) =>
      r == api.Role.owner ? Role.owner : Role.member;
  static api.Role _roleOf(Role r) =>
      r == Role.owner ? api.Role.owner : api.Role.member;

  static Household _household(api.Household h) => Household(
    id: h.id,
    name: h.name,
    timeZone: h.timeZone,
    cycle: _cycle(h.cycle),
    role: _role(h.role),
    frozen: h.frozen,
    memberCount: h.memberCount,
    current: _period(h.current),
    next: h.next == null ? null : _period(h.next!),
    balanceMinor: h.balanceMinor,
  );

  static Member _member(api.Member m) => Member(
    userId: m.userId,
    email: m.email,
    name: m.name,
    role: _role(m.role),
    frozen: m.frozen,
    shareMinor: m.shareMinor,
  );

  static Invitation _invitation(api.Invitation i) => Invitation(
    id: i.id,
    householdId: i.householdId,
    householdName: i.householdName,
    email: i.email,
    invitedBy: i.invitedBy == null
        ? null
        : (i.invitedBy!.name ?? i.invitedBy!.email),
    expiresAt: DateTime.parse(i.expiresAt).toLocal(),
  );

  static PeriodSummary _summary(api.PeriodSummary s) => PeriodSummary(
    period: _period(s.period),
    transfersMinor: s.transfersMinor,
    withdrawalsMinor: s.withdrawalsMinor,
    carryInMinor: s.carryInMinor,
    spentMinor: s.spentMinor,
    estimatedSpentMinor: s.estimatedSpentMinor,
    balanceMinor: s.balanceMinor,
    plansTotalMinor: s.plansTotalMinor,
    freeMinor: s.freeMinor,
    plansExceedBalance: s.plansExceedBalance,
    carryOutMinor: s.carryOutMinor,
    nobodyLeftMinor: s.nobodyLeftMinor,
    envelopes: [
      for (final e in s.envelopes)
        EnvelopeFigures(
          envelopeId: e.envelopeId,
          name: e.name,
          color: e.color,
          icon: e.icon,
          archived: e.archived,
          planMinor: e.planMinor,
          manualMinor: e.manualMinor,
          recurringMinor: e.recurringMinor,
          spentMinor: e.spentMinor,
          leftMinor: e.leftMinor,
          sharePercent: (e.sharePercent as num).toDouble(),
          previousSpentMinor: e.previousSpentMinor,
        ),
    ],
    shares: [
      for (final p in s.shares)
        ShareFigures(
          userId: p.userId,
          name: p.name,
          member: p.member,
          transfersMinor: p.transfersMinor,
          withdrawalsMinor: p.withdrawalsMinor,
          spentMinor: p.spentMinor,
          fromNobodyMinor: p.fromNobodyMinor,
          shareMinor: p.shareMinor,
        ),
    ],
    forecast: s.forecast == null
        ? null
        : Forecast(
            variableMinor: s.forecast!.variableMinor,
            recurringMinor: s.forecast!.recurringMinor,
            projectedSpentMinor: s.forecast!.projectedSpentMinor,
            projectedBalanceMinor: s.forecast!.projectedBalanceMinor,
          ),
  );

  static ClosedSummary _closedSummary(api.ClosedSummary s) => ClosedSummary(
    periodId: s.periodId,
    householdId: s.householdId,
    householdName: s.householdName,
    startsOn: parseDay(s.startsOn),
    endsOn: parseDay(s.endsOn),
    transfersMinor: s.transfersMinor - s.withdrawalsMinor,
    carryInMinor: s.carryInMinor,
    spentMinor: s.spentMinor,
    carryOutMinor: s.carryOutMinor,
  );

  static MoveOutcome _moveOutcome(api.MoveResult r) => MoveOutcome(
    walletMinor: r.walletMinor,
    usedUnconfirmed: r.usedUnconfirmed,
    plansExceedBalance: r.plansExceedBalance,
  );

  static WalletEntry _walletEntry(api.WalletEntry w) => WalletEntry(
    id: w.id,
    kind: switch (w.kind) {
      api.WalletEntryKind.transfer => WalletEntryKind.transfer,
      api.WalletEntryKind.withdrawal => WalletEntryKind.withdrawal,
      api.WalletEntryKind.valueReturn => WalletEntryKind.giveBack,
      _ => WalletEntryKind.income,
    },
    amountMinor: w.amountMinor,
    onDate: parseDay(w.onDate),
    note: w.note,
    estimated: w.estimated,
    householdName: w.householdName,
    ruleId: w.ruleId,
  );

  static api.Decision _decision(Decision d) => api.Decision(
    raisePlan: d.raisePlan,
    transferMinor: d.transferMinor,
    allowNegativeWallet: d.allowNegativeWallet,
  );

  static api.Correction _correction(Correction c) => api.Correction(
    allowNegative: c.allowNegative,
    withdrawFromPeriodId: c.withdrawFromPeriodId,
  );

  static api.SaveExpense _saveExpense(ExpenseDraft d, Decision? decision) =>
      api.SaveExpense(
        envelopeId: d.envelopeId,
        amountMinor: d.amountMinor,
        spentAt: d.spentAt.toUtc().toIso8601String(),
        title: d.title,
        forWhom: switch (d.forWhom) {
          ForWhom.member => api.ForWhom.member,
          ForWhom.shared => api.ForWhom.shared,
          null => null,
        },
        forWhomUserId: d.forWhom == ForWhom.member ? d.forWhomUserId : null,
        decision: decision == null ? null : _decision(decision),
      );

  static Expense _expense(api.Expense x) => Expense(
    id: x.id,
    householdId: x.householdId,
    periodId: x.periodId,
    envelopeId: x.envelopeId,
    createdBy: x.createdBy,
    authorName: x.authorName,
    amountMinor: x.amountMinor,
    spentAt: DateTime.parse(x.spentAt).toLocal(),
    title: x.title,
    forWhom: switch (x.forWhom) {
      api.ForWhom.member => ForWhom.member,
      api.ForWhom.shared => ForWhom.shared,
      _ => null,
    },
    forWhomUserId: x.forWhomUserId,
    forWhomName: x.forWhomName,
    estimated: x.estimated,
    ruleId: x.ruleId,
  );

  static ExpenseOutcome _expenseOutcome(api.ExpenseResult r) => ExpenseOutcome(
    expense: _expense(r.expense),
    transferredMinor: r.transferredMinor,
    raisedPlanMinor: r.raisedPlanMinor,
    plansExceedBalance: r.plansExceedBalance,
  );

  static RuleKind _ruleKind(api.RuleKind k) => switch (k) {
    api.RuleKind.transfer => RuleKind.transfer,
    api.RuleKind.expense => RuleKind.expense,
    _ => RuleKind.income,
  };

  static RecurringRule _rule(api.RecurringRule r) => RecurringRule(
    id: r.id,
    kind: _ruleKind(r.kind),
    userId: r.userId,
    householdId: r.householdId,
    envelopeId: r.envelopeId,
    name: r.name,
    amountMinor: r.amountMinor,
    estimated: r.estimated,
    frequency: r.frequency == api.RecurringRuleFrequency.weeks
        ? RuleFrequency.weeks
        : RuleFrequency.monthly,
    dayOfMonth: r.dayOfMonth,
    everyWeeks: r.everyWeeks,
    anchorOn: r.anchorOn == null ? null : parseDay(r.anchorOn!),
    startsOn: parseDay(r.startsOn),
    toNextPeriod: r.target == api.RecurringRuleTarget.next,
    active: r.active,
  );

  static api.SaveRule _saveRule(RecurringRule r) => api.SaveRule(
    kind: switch (r.kind) {
      RuleKind.income => api.RuleKind.income,
      RuleKind.transfer => api.RuleKind.transfer,
      RuleKind.expense => api.RuleKind.expense,
    },
    householdId: r.kind == RuleKind.income ? null : r.householdId,
    envelopeId: r.kind == RuleKind.expense ? r.envelopeId : null,
    name: r.name,
    amountMinor: r.amountMinor,
    estimated: r.kind == RuleKind.transfer ? false : r.estimated,
    frequency: r.frequency == RuleFrequency.weeks
        ? api.SaveRuleFrequency.weeks
        : api.SaveRuleFrequency.monthly,
    dayOfMonth: r.frequency == RuleFrequency.monthly
        ? (r.dayOfMonth ?? 1)
        : null,
    everyWeeks: r.frequency == RuleFrequency.weeks ? (r.everyWeeks ?? 1) : null,
    anchorOn: r.anchorOn == null ? null : formatDay(r.anchorOn!),
    startsOn: r.startsOn == null ? null : formatDay(r.startsOn!),
    target: r.kind == RuleKind.transfer
        ? (r.toNextPeriod
              ? api.SaveRuleTarget.next
              : api.SaveRuleTarget.current)
        : null,
    active: r.active,
  );

  static TodoItem _todo(api.TodoItem t) => TodoItem(
    id: t.id,
    kind: switch (t.kind) {
      api.TodoKind.transferNoMoney => TodoKind.transferNoMoney,
      api.TodoKind.expenseNotFit => TodoKind.expenseNotFit,
      api.TodoKind.expenseEstimate => TodoKind.expenseEstimate,
      api.TodoKind.expenseMissed => TodoKind.expenseMissed,
      _ => TodoKind.incomeEstimate,
    },
    householdId: t.householdId,
    householdName: t.householdName,
    periodId: t.periodId,
    refId: t.refId,
    envelopeId: t.envelopeId,
    occurrenceOn: t.occurrenceOn == null ? null : parseDay(t.occurrenceOn!),
    amountMinor: t.amountMinor,
    title: t.title,
  );
}

/// A day as the API writes it, `YYYY-MM-DD`.
String formatDay(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

/// A day from the API, as a local date at midnight.
DateTime parseDay(String text) {
  final parts = text.split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}
