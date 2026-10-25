import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/planner_repository.dart';
import '../models/models.dart';
import '../models/category_progress.dart';
import '../models/period_summary.dart';

/// App-wide state for the current planning period.
///
/// Wraps [PlannerRepository] and exposes the current period, its category
/// progress, and the derived totals every screen reads (planned, spent,
/// remaining, unallocated).
class PlannerState extends ChangeNotifier {
  PlannerState({PlannerRepository? repository, FlutterSecureStorage? storage})
    : _repo = repository ?? PlannerRepository(),
      _storage = storage ?? const FlutterSecureStorage();

  static const _kCurrentPeriod = 'current_period_id';

  final PlannerRepository _repo;
  final FlutterSecureStorage _storage;

  Future<void> _persistCurrent() async {
    final id = _currentPeriod?.id;
    if (id == null) {
      await _storage.delete(key: _kCurrentPeriod);
    } else {
      await _storage.write(key: _kCurrentPeriod, value: '$id');
    }
  }

  bool _loading = true;
  bool get isLoading => _loading;

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

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    _categories = await _repo.getCategories();
    _recurringRules = await _repo.getRecurringRules();
    _periods = await _repo.getPeriods();

    // Restore the last chosen set, falling back to the most recent one.
    final storedId = int.tryParse(
      await _storage.read(key: _kCurrentPeriod) ?? '',
    );
    Period? chosen;
    for (final p in _periods) {
      if (p.id == storedId) {
        chosen = p;
        break;
      }
    }
    _currentPeriod = chosen ?? (_periods.isNotEmpty ? _periods.first : null);
    await _refreshProgress();

    _loading = false;
    notifyListeners();
  }

  /// Switch the dashboard to another existing period, remembering the choice.
  Future<void> selectPeriod(int periodId) async {
    final match = _periods.where((p) => p.id == periodId);
    if (match.isEmpty || match.first.id == _currentPeriod?.id) return;
    _currentPeriod = match.first;
    await _persistCurrent();
    await _refreshProgress();
    notifyListeners();
  }

  Future<void> _refreshProgress() async {
    final period = _currentPeriod;
    _progress = period?.id == null
        ? const []
        : await _repo.categoryProgress(period!.id!);
  }

  // ---- mutations ------------------------------------------------------------

  /// Creates a new period and its initial splits, then makes it current.
  Future<void> createPeriod({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required double income,
    required Map<int, double> plannedByCategory,
  }) async {
    final periodId = await _repo.insertPeriod(
      Period(
        name: name,
        startDate: startDate,
        endDate: endDate,
        income: income,
      ),
    );

    for (final entry in plannedByCategory.entries) {
      if (entry.value <= 0) continue;
      await _repo.insertSplit(
        Split(
          periodId: periodId,
          categoryId: entry.key,
          plannedAmount: entry.value,
        ),
      );
    }

    _periods = await _repo.getPeriods();
    _currentPeriod = await _repo.getCurrentPeriod();
    await _persistCurrent();
    await _refreshProgress();
    notifyListeners();
  }

  /// Edits the current period's income and per-category allocations.
  ///
  /// For each category: allocates/updates a split when the amount is positive;
  /// when the amount is zero it removes the split — unless money was already
  /// spent against it, in which case the split is kept at 0 so history stays
  /// intact.
  Future<void> editCurrentPeriodPlan({
    required double income,
    required Map<int, double> plannedByCategory,
  }) async {
    final period = _currentPeriod;
    if (period?.id == null) return;

    await _repo.updatePeriod(period!.copyWith(income: income));

    final existing = {
      for (final s in await _repo.getSplitsForPeriod(period.id!))
        s.categoryId: s,
    };

    for (final entry in plannedByCategory.entries) {
      final split = existing[entry.key];
      if (entry.value > 0) {
        if (split == null) {
          await _repo.insertSplit(
            Split(
              periodId: period.id!,
              categoryId: entry.key,
              plannedAmount: entry.value,
            ),
          );
        } else if (split.plannedAmount != entry.value) {
          await _repo.updateSplit(split.copyWith(plannedAmount: entry.value));
        }
      } else if (split != null) {
        final hasExpenses = (await _repo.getExpensesForSplit(
          split.id!,
        )).isNotEmpty;
        if (hasExpenses) {
          await _repo.updateSplit(split.copyWith(plannedAmount: 0));
        } else {
          await _repo.deleteSplit(split.id!);
        }
      }
    }

    _periods = await _repo.getPeriods();
    _currentPeriod = _periods.firstWhere(
      (p) => p.id == period.id,
      orElse: () => period,
    );
    await _refreshProgress();
    notifyListeners();
  }

  /// Deletes a period and all its data. If it was the current one, falls back
  /// to the most recent remaining period.
  Future<void> deletePeriod(int periodId) async {
    await _repo.deletePeriod(periodId);
    _periods = await _repo.getPeriods();
    if (_currentPeriod?.id == periodId) {
      _currentPeriod = _periods.isNotEmpty ? _periods.first : null;
      await _persistCurrent();
    }
    await _refreshProgress();
    notifyListeners();
  }

  Future<void> addExpense({
    required int splitId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    await _repo.insertExpense(
      Expense(splitId: splitId, amount: amount, date: date, note: note),
    );
    await _refreshProgress();
    notifyListeners();
  }

  Future<List<Expense>> expensesForSplit(int splitId) =>
      _repo.getExpensesForSplit(splitId);

  Future<List<PeriodSummary>> periodSummaries() => _repo.periodSummaries();

  /// Transactions (expenses + category) for the current period, newest first.
  Future<List<Transaction>> currentPeriodTransactions() async {
    final id = _currentPeriod?.id;
    if (id == null) return const [];
    final rows = await _repo.periodTransactions(id);
    return rows.map(Transaction.fromMap).toList();
  }

  Future<List<CategoryProgress>> progressForPeriod(int periodId) =>
      _repo.categoryProgress(periodId);

  Future<void> updateExpense(Expense expense) async {
    await _repo.updateExpense(expense);
    await _refreshProgress();
    notifyListeners();
  }

  Future<void> deleteExpense(int expenseId) async {
    await _repo.deleteExpense(expenseId);
    await _refreshProgress();
    notifyListeners();
  }

  Future<void> addCategory(Category category) async {
    await _repo.insertCategory(category);
    _categories = await _repo.getCategories();
    notifyListeners();
  }

  /// Creates a category and immediately makes it an envelope (planned 0) in the
  /// current period, so it can be spent against right away. Returns the new
  /// split id, or null if there is no current period.
  Future<int?> quickAddEnvelope(Category category) async {
    final period = _currentPeriod;
    if (period?.id == null) return null;
    final categoryId = await _repo.insertCategory(category);
    final splitId = await _repo.insertSplit(
      Split(periodId: period!.id!, categoryId: categoryId, plannedAmount: 0),
    );
    _categories = await _repo.getCategories();
    await _refreshProgress();
    notifyListeners();
    return splitId;
  }

  Future<void> updateCategory(Category category) async {
    await _repo.updateCategory(category);
    _categories = await _repo.getCategories();
    await _refreshProgress();
    notifyListeners();
  }

  /// Removes a category, refusing if it's still referenced by a split.
  /// Returns true on success, false if the category is in use.
  Future<bool> deleteCategory(int categoryId) async {
    if (await _repo.isCategoryInUse(categoryId)) return false;
    await _repo.deleteCategory(categoryId);
    _categories = await _repo.getCategories();
    notifyListeners();
    return true;
  }

  // ---- recurring rules ------------------------------------------------------

  Future<void> saveRecurringRule(RecurringRule rule) async {
    if (rule.id == null) {
      await _repo.insertRecurringRule(rule);
    } else {
      await _repo.updateRecurringRule(rule);
    }
    _recurringRules = await _repo.getRecurringRules();
    notifyListeners();
  }

  Future<void> deleteRecurringRule(int ruleId) async {
    await _repo.deleteRecurringRule(ruleId);
    _recurringRules = await _repo.getRecurringRules();
    notifyListeners();
  }

  /// Sum of active rules per category — used to pre-fill a new period's plan.
  Map<int, double> plannedFromRecurring() {
    final byCategory = <int, double>{};
    for (final rule in activeRecurringRules) {
      byCategory[rule.categoryId] =
          (byCategory[rule.categoryId] ?? 0) + rule.amount;
    }
    return byCategory;
  }

  /// Generates an expense in the current period for each active rule that
  /// hasn't been applied there yet, creating a split on demand. Returns the
  /// number of expenses added.
  Future<int> applyRecurringToCurrentPeriod() async {
    final period = _currentPeriod;
    if (period?.id == null) return 0;

    final applied = await _repo.appliedRecurringIds(period!.id!);
    var added = 0;
    for (final rule in activeRecurringRules) {
      if (applied.contains(rule.id)) continue;

      var split = await _repo.getSplitForCategory(period.id!, rule.categoryId);
      if (split == null) {
        final splitId = await _repo.insertSplit(
          Split(
            periodId: period.id!,
            categoryId: rule.categoryId,
            plannedAmount: rule.amount,
          ),
        );
        split = Split(
          id: splitId,
          periodId: period.id!,
          categoryId: rule.categoryId,
          plannedAmount: rule.amount,
        );
      }

      await _repo.insertExpense(
        Expense(
          splitId: split.id!,
          amount: rule.amount,
          date: DateTime.now(),
          note: rule.note,
          recurringId: rule.id,
        ),
      );
      added++;
    }

    if (added > 0) {
      await _refreshProgress();
      notifyListeners();
    }
    return added;
  }
}
