import 'dart:async';

import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/api_exception.dart';
import '../data/planner_repository.dart';
import '../models/category_progress.dart';
import '../models/models.dart';
import '../models/period_summary.dart';

/// The errors of the three requests `load` makes side by side.
typedef _Failures = (AsyncError?, AsyncError?, AsyncError?);

/// App-wide state for the current planning period.
///
/// Wraps [PlannerRepository] (the backend) and exposes the current period, its
/// category progress, and the derived totals every screen reads (planned,
/// spent, remaining, unallocated). The app needs the server, so a failed
/// request surfaces as [loadError] while loading, and as an [ApiException]
/// thrown from the method that was called otherwise.
class PlannerState extends ChangeNotifier {
  PlannerState({
    required PlannerRepository repository,
    this.beforeLoad,
    FlutterSecureStorage? storage,
  }) : _repo = repository,
       _storage = storage ?? const FlutterSecureStorage();

  static const _kCurrentPeriod = 'current_period_id';

  /// The last chosen period is remembered per budget.
  String get _periodKey => '$_kCurrentPeriod:${_spaceId ?? ''}';

  final PlannerRepository _repo;

  /// Runs first on every [load], e.g. to move old local data to the server.
  final Future<void> Function()? beforeLoad;
  final FlutterSecureStorage _storage;

  Future<void> _persistCurrent() async {
    final id = _currentPeriod?.id;
    if (id == null) {
      await _storage.delete(key: _periodKey);
    } else {
      await _storage.write(key: _periodKey, value: id);
    }
  }

  bool _loading = true;
  bool get isLoading => _loading;

  /// Why the last [load] failed, or null when it worked.
  ApiException? _loadError;
  ApiException? get loadError => _loadError;

  Period? _currentPeriod;
  Period? get currentPeriod => _currentPeriod;

  List<Period> _periods = const [];
  List<Period> get periods => _periods;

  List<Category> _categories = const [];
  List<Category> get categories => _categories;

  List<RecurringRule> _recurringRules = const [];
  List<RecurringRule> get recurringRules => _recurringRules;
  List<RecurringRule> get activeRecurringRules =>
      _recurringRules.where((r) => r.active).toList();

  List<CategoryProgress> _progress = const [];
  List<CategoryProgress> get progress => _progress;

  /// What was paid into the current period (shared budgets).
  double _contributed = 0;
  double get contributed => _contributed;

  // ---- derived totals -------------------------------------------------------

  double get income => _currentPeriod?.income ?? 0;

  double get totalPlanned => _progress.fold(0, (sum, p) => sum + p.planned);

  double get totalSpent => _progress.fold(0, (sum, p) => sum + p.spent);

  double get totalRemaining => totalPlanned - totalSpent;

  /// Income not yet assigned to any envelope — grows when a category is
  /// removed, shrinks as you allocate more. Can go negative if over-allocated.
  double get unallocated => income - totalPlanned;

  bool get isOverAllocated => unallocated < 0;

  // ---- lifecycle ------------------------------------------------------------

  String? _spaceId;

  /// Tells the state which budget to show: it loads that budget's data, and
  /// forgets everything for `null` (nobody signed in). Switching to another
  /// budget drops the old one's data first.
  void useSpace(String? id) {
    if (id == _spaceId) return;
    _spaceId = id;
    // this is called while the widget tree builds, so change state after it
    scheduleMicrotask(() async {
      await _forget();
      if (id != null && id == _spaceId) await load();
    });
  }

  Future<void> _forget() async {
    _categories = const [];
    _recurringRules = const [];
    _periods = const [];
    _progress = const [];
    _currentPeriod = null;
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
      final (categories, rules, periods) = await (
        _repo.categories(),
        _repo.recurringRules(),
        _repo.periods(),
      ).wait;
      _categories = categories;
      _recurringRules = rules;
      _periods = periods;

      // Restore the last chosen period, falling back to the most recent one.
      final storedId = await _storage.read(key: _periodKey);
      _currentPeriod =
          _periods.where((p) => p.id == storedId).firstOrNull ??
          _periods.firstOrNull;
      await _refreshProgress();
    } on ApiException catch (error) {
      _loadError = error;
    } on ParallelWaitError<Object?, _Failures> catch (error) {
      // the requests ran side by side: report the first that failed
      final (a, b, c) = error.errors;
      _loadError = [
        a?.error,
        b?.error,
        c?.error,
      ].whereType<ApiException>().firstOrNull;
      if (_loadError == null) rethrow;
    }

    _loading = false;
    notifyListeners();
  }

  /// Switch the dashboard to another existing period, remembering the choice.
  Future<void> selectPeriod(String periodId) async {
    final match = _periods.where((p) => p.id == periodId);
    if (match.isEmpty || match.first.id == _currentPeriod?.id) return;
    _currentPeriod = match.first;
    await _persistCurrent();
    await _refreshProgress();
    notifyListeners();
  }

  Future<void> _refreshProgress() async {
    final period = _currentPeriod;
    if (period == null) {
      _progress = const [];
      _contributed = 0;
      return;
    }
    final progress = await _repo.periodProgress(period, _categoriesById);
    _progress = progress.envelopes;
    _contributed = progress.contributed;
  }

  Map<String, Category> get _categoriesById => {
    for (final c in _categories) c.id!: c,
  };

  String get _currency => _currentPeriod?.currency ?? Period.defaultCurrency;

  // ---- periods --------------------------------------------------------------

  /// Creates a new period and its initial envelopes, then makes it current.
  Future<void> createPeriod({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required double income,
    required Map<String, double> plannedByCategory,
  }) async {
    final created = await _repo.createPeriod(
      name: name,
      startDate: startDate,
      endDate: endDate,
      income: income,
      plannedByCategory: plannedByCategory,
    );
    _periods = await _repo.periods();
    _currentPeriod = _periods.where((p) => p.id == created.id).firstOrNull;
    await _persistCurrent();
    await _refreshProgress();
    notifyListeners();
  }

  /// Edits the current period's income and per-category allocations.
  ///
  /// For each category: allocates/updates an envelope when the amount is
  /// positive; when it is zero the envelope is removed — unless money was
  /// already spent from it, in which case it stays at 0 so history stays
  /// intact. The server applies those rules.
  Future<void> editCurrentPeriodPlan({
    required double income,
    required Map<String, double> plannedByCategory,
  }) async {
    final period = _currentPeriod;
    if (period == null) return;

    final Period updated;
    try {
      updated = await _repo.setPlan(
        period,
        income: income,
        plannedByCategory: plannedByCategory,
      );
    } on ApiException catch (error) {
      // somebody else edited the plan: show what they saved before the user
      // is asked to edit again
      if (error.tag == 'PeriodChanged') await _reloadPeriods();
      rethrow;
    }
    _periods = [for (final p in _periods) p.id == updated.id ? updated : p];
    _currentPeriod = updated;
    await _refreshProgress();
    notifyListeners();
  }

  /// Fetches the progress of the current period again, e.g. after something
  /// was paid into it.
  Future<void> reloadProgress() async {
    try {
      await _refreshProgress();
      notifyListeners();
    } on ApiException {
      // the numbers on screen stay as they were
    }
  }

  /// Fetches the periods and the progress again, keeping the current period.
  Future<void> _reloadPeriods() async {
    final id = _currentPeriod?.id;
    _periods = await _repo.periods();
    _currentPeriod =
        _periods.where((p) => p.id == id).firstOrNull ?? _periods.firstOrNull;
    await _refreshProgress();
    notifyListeners();
  }

  /// Deletes a period and all its data. If it was the current one, falls back
  /// to the most recent remaining period.
  Future<void> deletePeriod(String periodId) async {
    await _repo.deletePeriod(periodId);
    _periods = await _repo.periods();
    if (_currentPeriod?.id == periodId) {
      _currentPeriod = _periods.firstOrNull;
      await _persistCurrent();
    }
    await _refreshProgress();
    notifyListeners();
  }

  Future<List<PeriodSummary>> periodSummaries() => _repo.periodSummaries();

  /// Planned versus spent per envelope of any period.
  Future<List<CategoryProgress>> progressForPeriod(Period period) =>
      _repo.categoryProgress(period, _categoriesById);

  // ---- expenses -------------------------------------------------------------

  Future<void> addExpense({
    required String envelopeId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    await _repo.createExpense(
      Expense(envelopeId: envelopeId, amount: amount, date: date, note: note),
      _currency,
    );
    await _refreshProgress();
    notifyListeners();
  }

  Future<void> updateExpense(Expense expense) async {
    await _repo.updateExpense(expense, _currency);
    await _refreshProgress();
    notifyListeners();
  }

  Future<void> deleteExpense(String expenseId) async {
    await _repo.deleteExpense(expenseId);
    await _refreshProgress();
    notifyListeners();
  }

  /// Expenses drawn from one envelope of the current period, newest first.
  Future<List<Expense>> expensesForEnvelope(String envelopeId) {
    final period = _currentPeriod;
    return period == null
        ? Future.value(const [])
        : _repo.expenses(period, envelopeId: envelopeId);
  }

  /// Transactions (expenses + category) for the current period, newest first.
  Future<List<Transaction>> currentPeriodTransactions() {
    final period = _currentPeriod;
    if (period == null) return Future.value(const []);
    return _repo.transactions(period, {
      for (final p in _progress) p.envelope.id!: p.category,
    });
  }

  // ---- categories -----------------------------------------------------------

  Future<void> addCategory(Category category) async {
    await _repo.createCategory(category);
    _categories = await _repo.categories();
    notifyListeners();
  }

  /// Creates a category and immediately makes it an envelope (planned 0) in the
  /// current period, so it can be spent against right away. Returns the new
  /// envelope id, or null if there is no current period.
  Future<String?> quickAddEnvelope(Category category) async {
    final period = _currentPeriod;
    if (period == null) return null;
    final created = await _repo.createCategory(category);
    final envelope = await _repo.addEnvelope(period, created.id!);
    _categories = await _repo.categories();
    await _refreshProgress();
    notifyListeners();
    return envelope.id;
  }

  Future<void> updateCategory(Category category) async {
    await _repo.updateCategory(category);
    _categories = await _repo.categories();
    await _refreshProgress();
    notifyListeners();
  }

  /// Removes a category, refusing if an envelope still uses it.
  /// Returns true on success, false if the category is in use.
  Future<bool> deleteCategory(String categoryId) async {
    if (!await _repo.deleteCategory(categoryId)) return false;
    _categories = await _repo.categories();
    notifyListeners();
    return true;
  }

  // ---- recurring rules ------------------------------------------------------

  Future<void> saveRecurringRule(RecurringRule rule) async {
    await _repo.saveRecurringRule(rule);
    _recurringRules = await _repo.recurringRules();
    notifyListeners();
  }

  Future<void> deleteRecurringRule(String ruleId) async {
    await _repo.deleteRecurringRule(ruleId);
    _recurringRules = await _repo.recurringRules();
    notifyListeners();
  }

  /// Sum of active rules per category — used to pre-fill a new period's plan.
  Map<String, double> plannedFromRecurring() {
    final byCategory = <String, double>{};
    for (final rule in activeRecurringRules) {
      if (rule.currency != Period.defaultCurrency) continue;
      byCategory[rule.categoryId] =
          (byCategory[rule.categoryId] ?? 0) + rule.amount;
    }
    return byCategory;
  }

  /// Adds an expense to the current period for each active rule that hasn't
  /// been applied there yet. Returns the number of expenses added.
  Future<int> applyRecurringToCurrentPeriod() async {
    final period = _currentPeriod;
    if (period == null) return 0;

    final added = await _repo.applyRecurringRules(period);
    if (added > 0) {
      await _refreshProgress();
      notifyListeners();
    }
    return added;
  }
}
