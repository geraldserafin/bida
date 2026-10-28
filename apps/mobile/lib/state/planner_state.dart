import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/api_exception.dart';
import '../data/planner_repository.dart';
import '../models/models.dart';

/// App-wide state for the month on screen.
///
/// Wraps [PlannerRepository] (the backend) and exposes the envelopes, the
/// figures of the selected month and the totals every screen reads. The app
/// needs the server, so a failed request surfaces as [loadError] while
/// loading, and as an [ApiException] thrown from the method that was called
/// otherwise.
class PlannerState extends ChangeNotifier {
  PlannerState({
    required PlannerRepository repository,
    this.beforeLoad,
    DateTime Function()? clock,
  }) : _repo = repository,
       _clock = clock ?? DateTime.now;

  final PlannerRepository _repo;
  final DateTime Function() _clock;

  /// Runs first on every [load], e.g. to move old local data to the server.
  final Future<void> Function()? beforeLoad;

  bool _loading = true;
  bool get isLoading => _loading;

  /// Why the last [load] failed, or null when it worked.
  ApiException? _loadError;
  ApiException? get loadError => _loadError;

  List<Envelope> _envelopes = const [];

  /// Every envelope, by name: top-level ones and sub-envelopes together.
  List<Envelope> get envelopes => _envelopes;

  List<Envelope> get topLevel => [
    for (final e in _envelopes)
      if (e.isTopLevel) e,
  ];

  List<Envelope> childrenOf(String envelopeId) => [
    for (final e in _envelopes)
      if (e.parentId == envelopeId) e,
  ];

  Envelope? envelopeById(String? id) =>
      _envelopes.where((e) => e.id == id).firstOrNull;

  Map<String, Envelope> get _envelopesById => {
    for (final e in _envelopes) e.id!: e,
  };

  List<RecurringRule> _recurringRules = const [];
  List<RecurringRule> get recurringRules => _recurringRules;

  List<RecurringIncome> _recurringIncomes = const [];
  List<RecurringIncome> get recurringIncomes => _recurringIncomes;

  List<AllocationRule> _allocationRules = const [];
  List<AllocationRule> get allocationRules => _allocationRules;

  ApplyOutcome _pending = const ApplyOutcome();

  /// What applying the recurring rules to the month on screen would add.
  ApplyOutcome get pending => _pending;

  List<Invitation> _invitations = const [];

  /// Invitations to share an envelope that wait for the user's answer.
  List<Invitation> get invitations => _invitations;

  // ---- the month on screen ---------------------------------------------------

  int _firstDay = 1;
  BudgetMonth? _month;

  /// The month the figures are for. Today's month until another is chosen.
  BudgetMonth get month =>
      _month ?? BudgetMonth.containing(_clock(), firstDay: _firstDay);

  bool get isCurrentMonth =>
      month == BudgetMonth.containing(_clock(), firstDay: _firstDay);

  Overview _overview = Overview.empty(BudgetMonth.containing(DateTime.now()));
  Overview get overview => _overview;

  /// The figures of every envelope, top-level ones and sub-envelopes together.
  List<EnvelopeProgress> get progress => _overview.envelopes;

  EnvelopeProgress? progressOf(String? envelopeId) =>
      progress.where((p) => p.envelope.id == envelopeId).firstOrNull;

  /// The figures of the top-level envelopes.
  List<EnvelopeProgress> get topLevelProgress => [
    for (final p in progress)
      if (p.envelope.isTopLevel) p,
  ];

  List<EnvelopeProgress> childrenProgressOf(String envelopeId) => [
    for (final p in progress)
      if (p.envelope.parentId == envelopeId) p,
  ];

  // ---- derived totals --------------------------------------------------------

  /// Income received in the month.
  double get income => _overview.income;

  /// What was put into envelopes in the month.
  double get allocated => _overview.allocated;

  double get spent => _overview.spent;

  /// Income not yet put into any envelope. Negative when more was put in than
  /// came in.
  double get pool => _overview.pool;

  bool get isOverAllocated => pool < 0;

  /// Whether there is anything to show yet.
  bool get isEmpty => _envelopes.isEmpty && income == 0 && pool == 0;

  // ---- lifecycle -------------------------------------------------------------

  bool _signedIn = false;

  /// Tells the state whether somebody is signed in: it loads their data when
  /// they are, and forgets it when they sign out.
  void signedIn(bool value) {
    if (value == _signedIn) return;
    _signedIn = value;
    // this is called while the widget tree builds, so change state after it
    scheduleMicrotask(() => value ? load() : _forget());
  }

  /// Tells the state which day of the month the user's months start on.
  void useFirstDay(int day) {
    if (day == _firstDay) return;
    _firstDay = day;
    _month = null;
    if (_signedIn) scheduleMicrotask(() => _reloadOverview());
  }

  Future<void> _forget() async {
    _envelopes = const [];
    _recurringRules = const [];
    _invitations = const [];
    _recurringIncomes = const [];
    _allocationRules = const [];
    _pending = const ApplyOutcome();
    _overview = Overview.empty(month);
    _month = null;
    _loadError = null;
    _loading = true;
    notifyListeners();
  }

  /// Fetches everything from the server. Call again to retry after a failure.
  Future<void> load() async {
    _loading = true;
    _loadError = null;
    notifyListeners();

    try {
      await beforeLoad?.call();
      final (envelopes, rules, invitations, incomeRules, allocations) = await (
        _repo.envelopes(),
        _repo.recurringRules(),
        _repo.myInvitations(),
        _repo.recurringIncomes(),
        _repo.allocationRules(),
      ).wait;
      _envelopes = envelopes;
      _recurringRules = rules;
      _invitations = invitations;
      _recurringIncomes = incomeRules;
      _allocationRules = allocations;
      _overview = await _repo.overview(month, _envelopesById);
      await _refreshPending();
    } on ApiException catch (error) {
      _loadError = error;
    } on ParallelWaitError<
      Object?,
      (AsyncError?, AsyncError?, AsyncError?, AsyncError?, AsyncError?)
    > catch (error) {
      // the requests ran side by side: report the first that failed
      final (a, b, c, d, e) = error.errors;
      _loadError = [
        a?.error,
        b?.error,
        c?.error,
        d?.error,
        e?.error,
      ].whereType<ApiException>().firstOrNull;
      if (_loadError == null) rethrow;
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> _reloadOverview() async {
    try {
      _overview = await _repo.overview(month, _envelopesById);
    } on ApiException {
      // the numbers on screen stay as they were
    }
    notifyListeners();
  }

  /// Fetches the envelopes and the figures again.
  Future<void> _reloadAll() async {
    _envelopes = await _repo.envelopes();
    _overview = await _repo.overview(month, _envelopesById);
    notifyListeners();
  }

  /// Fetches the figures again, e.g. after something was changed elsewhere.
  Future<void> reloadOverview() async {
    _overview = await _repo.overview(month, _envelopesById);
    notifyListeners();
  }

  // ---- months ----------------------------------------------------------------

  /// Shows another month.
  Future<void> selectMonth(BudgetMonth month) async {
    if (month == this.month) return;
    _overview = await _repo.overview(month, _envelopesById);
    _month = month;
    await _refreshPending();
    notifyListeners();
  }

  Future<void> previousMonth() => selectMonth(month.previous);

  Future<void> nextMonth() => selectMonth(month.next);

  Future<void> goToCurrentMonth() =>
      selectMonth(BudgetMonth.containing(_clock(), firstDay: _firstDay));

  /// Every month with something in it, newest first.
  Future<List<MonthSummary>> monthSummaries() =>
      _repo.months(firstDay: _firstDay);

  // ---- envelopes ---------------------------------------------------------------

  /// Creates an envelope and returns it.
  Future<Envelope> addEnvelope(Envelope envelope) async {
    final created = await _repo.createEnvelope(envelope);
    await _reloadAll();
    return created;
  }

  Future<void> updateEnvelope(Envelope envelope) async {
    await _repo.updateEnvelope(envelope);
    await _reloadAll();
  }

  /// Deletes the envelope with its sub-envelopes, expenses and allocations.
  Future<void> deleteEnvelope(String envelopeId) async {
    await _repo.deleteEnvelope(envelopeId);
    _recurringRules = await _repo.recurringRules();
    await _reloadAll();
  }

  // ---- income ------------------------------------------------------------------

  /// Everything that came in, newest first.
  Future<List<Income>> incomes() => _repo.incomes();

  Future<void> saveIncome(Income income) async {
    await _repo.saveIncome(income);
    await reloadOverview();
  }

  Future<void> deleteIncome(String incomeId) async {
    await _repo.deleteIncome(incomeId);
    await reloadOverview();
  }

  // ---- allocations -------------------------------------------------------------

  /// What was put into the envelope (and its sub-envelopes), newest first.
  Future<List<Allocation>> allocationsFor(String envelopeId) =>
      _repo.allocations(envelopeId: envelopeId);

  /// Puts money into an envelope, or takes it out when the amount is negative.
  /// Throws an [ApiException] tagged `NotEnoughMoney` when it cannot.
  Future<void> saveAllocation(Allocation allocation) async {
    await _repo.saveAllocation(allocation);
    await reloadOverview();
  }

  Future<void> deleteAllocation(String allocationId) async {
    await _repo.deleteAllocation(allocationId);
    await reloadOverview();
  }

  // ---- expenses ----------------------------------------------------------------

  Future<void> addExpense({
    required String envelopeId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    await _repo.createExpense(
      Expense(envelopeId: envelopeId, amount: amount, date: date, note: note),
    );
    await reloadOverview();
  }

  Future<void> updateExpense(Expense expense) async {
    await _repo.updateExpense(expense);
    await reloadOverview();
  }

  Future<void> deleteExpense(String expenseId) async {
    await _repo.deleteExpense(expenseId);
    await reloadOverview();
  }

  /// Expenses of one envelope (and its sub-envelopes) in the month, newest first.
  Future<List<Expense>> expensesForEnvelope(String envelopeId) =>
      _repo.expenses(month: month, envelopeId: envelopeId);

  /// Expenses of the month joined with their envelope, newest first.
  Future<List<Transaction>> monthTransactions() =>
      _repo.transactions(month, _envelopesById);

  // ---- recurring rules ---------------------------------------------------------

  Future<void> saveRecurringRule(RecurringRule rule) async {
    await _repo.saveRecurringRule(rule);
    _recurringRules = await _repo.recurringRules();
    await _refreshPending();
    notifyListeners();
  }

  Future<void> deleteRecurringRule(String ruleId) async {
    await _repo.deleteRecurringRule(ruleId);
    _recurringRules = await _repo.recurringRules();
    await _refreshPending();
    notifyListeners();
  }

  /// Adds to the month what every active rule that has not been applied there
  /// yet makes: incomes, allocations and expenses.
  Future<ApplyOutcome> applyRecurringToMonth() async {
    final outcome = await _repo.applyRecurringRules(month);
    if (outcome.added > 0) await reloadOverview();
    await _refreshPending();
    notifyListeners();
    return outcome;
  }

  /// Asks again what applying the rules would add; the answer stays as it was
  /// when the server cannot be reached.
  Future<void> _refreshPending() async {
    try {
      _pending = await _repo.pendingRecurring(month);
    } on ApiException {
      // a hint, not worth a failed screen
    }
  }

  Future<void> saveRecurringIncome(RecurringIncome rule) async {
    await _repo.saveRecurringIncome(rule);
    _recurringIncomes = await _repo.recurringIncomes();
    await _refreshPending();
    notifyListeners();
  }

  Future<void> deleteRecurringIncome(String ruleId) async {
    await _repo.deleteRecurringIncome(ruleId);
    _recurringIncomes = await _repo.recurringIncomes();
    await _refreshPending();
    notifyListeners();
  }

  Future<void> saveAllocationRule(AllocationRule rule) async {
    await _repo.saveAllocationRule(rule);
    _allocationRules = await _repo.allocationRules();
    await _refreshPending();
    notifyListeners();
  }

  Future<void> deleteAllocationRule(String ruleId) async {
    await _repo.deleteAllocationRule(ruleId);
    _allocationRules = await _repo.allocationRules();
    await _refreshPending();
    notifyListeners();
  }

  // ---- sharing -----------------------------------------------------------------

  /// The people who share the envelope (its parent's, for a sub-envelope).
  Future<List<Member>> membersOf(String envelopeId) =>
      _repo.members(envelopeId);

  /// Who put how much into the envelope and its sub-envelopes.
  Future<List<Contribution>> contributionsOf(String envelopeId) =>
      _repo.contributions(envelopeId);

  /// The invitations of the envelope that wait for an answer or for approval.
  Future<List<Invitation>> invitationsOf(String envelopeId) =>
      _repo.envelopeInvitations(envelopeId);

  Future<void> invite(
    String envelopeId, {
    required String email,
    required EnvelopeRole role,
  }) async {
    await _repo.invite(envelopeId, email: email, role: role);
  }

  Future<void> revokeInvitation(String envelopeId, String invitationId) =>
      _repo.revokeInvitation(envelopeId, invitationId);

  /// Lets in somebody who accepted an invitation.
  Future<void> approveInvitation(String envelopeId, String invitationId) async {
    await _repo.approveInvitation(envelopeId, invitationId);
    await reloadOverview(); // the envelope has one more member now
  }

  Future<void> setRole(String envelopeId, String userId, EnvelopeRole role) =>
      _repo.setRole(envelopeId, userId, role);

  /// Removes a member. [leaving] is for the user taking themselves out, after
  /// which the envelope is not theirs to see any more.
  Future<void> removeMember(
    String envelopeId,
    String userId, {
    bool leaving = false,
  }) async {
    await _repo.removeMember(envelopeId, userId);
    _recurringRules = await _repo.recurringRules();
    if (leaving) {
      await _reloadAll();
    } else {
      await reloadOverview();
    }
  }

  /// Says yes to an invitation. Nobody gets in before an owner approves.
  Future<void> acceptInvitation(String invitationId) async {
    await _repo.acceptInvitation(invitationId);
    _invitations = await _repo.myInvitations();
    notifyListeners();
  }

  Future<void> declineInvitation(String invitationId) async {
    await _repo.declineInvitation(invitationId);
    _invitations = await _repo.myInvitations();
    notifyListeners();
  }
}
