import 'package:bida_api_client/bida_api_client.dart' as api;
import 'package:dio/dio.dart';

import '../models/category_progress.dart';
import '../models/models.dart';
import '../models/period_summary.dart';
import 'api_exception.dart';
import 'mappers.dart';
import 'money.dart';

/// Single entry point to the backend, in the app's own terms. Every method
/// either returns app models or throws an [ApiException].
class PlannerRepository {
  PlannerRepository(this._dio, {this.pageSize = 200})
    : _api = api.BidaApi(_dio);

  final Dio _dio;
  final api.BidaApi _api;

  /// Expenses come in pages of this size (the API allows at most 200).
  final int pageSize;

  // -------------------------------------------------------------------- server

  Future<({String status, int uptimeSeconds})> health() => guard(() async {
    final health = await _api.system.systemHealth();
    return (
      status: health.status.json ?? 'unknown',
      uptimeSeconds: health.uptimeSeconds,
    );
  });

  // ---------------------------------------------------------------- categories

  Future<List<Category>> categories() => guard(() async {
    final all = await _api.categories.categoriesList();
    return all.map(categoryFrom).toList();
  });

  Future<Category> createCategory(Category category) => guard(
    () async => categoryFrom(
      await _api.categories.categoriesCreate(body: createCategoryOf(category)),
    ),
  );

  Future<Category> updateCategory(Category category) => guard(
    () async => categoryFrom(
      await _api.categories.categoriesUpdate(
        id: category.id!,
        body: updateCategoryOf(category),
      ),
    ),
  );

  /// Returns false, and deletes nothing, when an envelope still uses it.
  Future<bool> deleteCategory(String id) async {
    try {
      await guard(() => _api.categories.categoriesDelete(id: id));
      return true;
    } on ApiException catch (error) {
      if (error.tag == 'CategoryInUse') return false;
      rethrow;
    }
  }

  // ------------------------------------------------------------------- periods

  /// Newest first.
  Future<List<Period>> periods() => guard(() async {
    final all = await _api.periods.periodsList();
    return all.map(periodFrom).toList();
  });

  Future<List<PeriodSummary>> periodSummaries() => guard(() async {
    final all = await _api.expenses.expensesPeriodSummaries();
    return [
      for (final s in all)
        PeriodSummary(
          period: periodFrom(s.period),
          planned: fromMinor(s.plannedMinor, currencyCode(s.period.currency)),
          spent: fromMinor(s.spentMinor, currencyCode(s.period.currency)),
        ),
    ];
  });

  /// Creates the period together with its envelopes. Categories planned at 0
  /// get none.
  Future<Period> createPeriod({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required double income,
    required Map<String, double> plannedByCategory,
    String currency = Period.defaultCurrency,
  }) => guard(() async {
    final created = await _api.periods.periodsCreate(
      body: api.CreatePeriod(
        name: name,
        startDate: formatDay(startDate),
        endDate: formatDay(endDate),
        incomeMinor: toMinor(income, currency),
        currency: currencyOf(currency),
        envelopes: envelopePlansOf(plannedByCategory, currency),
      ),
    );
    return periodFrom(created.period);
  });

  /// Sets the income and the planned amount of the listed categories. An
  /// amount of 0 removes the envelope, or keeps it empty when it already has
  /// expenses.
  Future<Period> setPlan(
    Period period, {
    required double income,
    required Map<String, double> plannedByCategory,
  }) => guard(() async {
    final updated = await _api.periods.periodsSetPlan(
      id: period.id!,
      body: api.SetPlan(
        incomeMinor: toMinor(income, period.currency),
        envelopes: envelopePlansOf(plannedByCategory, period.currency),
      ),
    );
    return periodFrom(updated.period);
  });

  /// Deletes the period with its envelopes and expenses.
  Future<void> deletePeriod(String id) =>
      guard(() => _api.periods.periodsDelete(id: id));

  // ----------------------------------------------------------------- envelopes

  /// Planned versus spent for each envelope of the period. Envelopes of a
  /// category that is not in [categories] are left out.
  Future<List<CategoryProgress>> categoryProgress(
    Period period,
    Map<String, Category> categories,
  ) => guard(() async {
    final progress = await _api.expenses.expensesProgress(periodId: period.id!);
    return [
      for (final row in progress.envelopes)
        if (categories[row.categoryId] case final category?)
          CategoryProgress(
            category: category,
            envelope: envelopeFrom(row, period.id!, period.currency),
            spent: fromMinor(row.spentMinor, period.currency),
          ),
    ];
  });

  /// An empty envelope for the category, so it can be spent from right away.
  Future<Envelope> addEnvelope(Period period, String categoryId) =>
      guard(() async {
        final created = await _api.periods.periodsAddEnvelope(
          id: period.id!,
          body: api.EnvelopePlan(categoryId: categoryId, plannedMinor: 0),
        );
        return Envelope(
          id: created.id,
          periodId: created.periodId,
          categoryId: created.categoryId,
          plannedAmount: 0,
        );
      });

  // ------------------------------------------------------------------ expenses

  /// All expenses of the period, newest first. [envelopeId] narrows it to one
  /// envelope.
  Future<List<Expense>> expenses(Period period, {String? envelopeId}) =>
      guard(() async {
        final all = <Expense>[];
        for (var offset = 0; ; offset += pageSize) {
          final page = await _api.expenses.expensesListForPeriod(
            periodId: period.id!,
            envelopeId: envelopeId,
            limit: '$pageSize',
            offset: '$offset',
          );
          all.addAll(page.map((e) => expenseFrom(e, period.currency)));
          if (page.length < pageSize) return all;
        }
      });

  /// The period's expenses joined with their category, newest first.
  /// [categoryByEnvelope] says which category an envelope belongs to.
  Future<List<Transaction>> transactions(
    Period period,
    Map<String, Category> categoryByEnvelope,
  ) async {
    final all = await expenses(period);
    return [
      for (final expense in all)
        if (categoryByEnvelope[expense.envelopeId] case final category?)
          Transaction(expense: expense, category: category),
    ];
  }

  Future<Expense> createExpense(Expense expense, String currency) =>
      guard(() async {
        final created = await _api.expenses.expensesCreate(
          body: createExpenseOf(expense, currency),
        );
        return expenseFrom(created, currency);
      });

  Future<Expense> updateExpense(Expense expense, String currency) =>
      guard(() async {
        final updated = await _api.expenses.expensesUpdate(
          id: expense.id!,
          body: updateExpenseOf(expense, currency),
        );
        return expenseFrom(updated, currency);
      });

  Future<void> deleteExpense(String id) =>
      guard(() => _api.expenses.expensesDelete(id: id));

  // ----------------------------------------------------------------- recurring

  Future<List<RecurringRule>> recurringRules() => guard(() async {
    final all = await _api.recurring.recurringList();
    return all.map(ruleFrom).toList();
  });

  Future<RecurringRule> saveRecurringRule(RecurringRule rule) =>
      guard(() async {
        final saved = rule.id == null
            ? await _api.recurring.recurringCreate(body: saveRuleOf(rule))
            : await _api.recurring.recurringUpdate(
                id: rule.id!,
                body: saveRuleOf(rule),
              );
        return ruleFrom(saved);
      });

  Future<void> deleteRecurringRule(String id) =>
      guard(() => _api.recurring.recurringDelete(id: id));

  /// Adds an expense for every active rule not applied to the period yet.
  /// Returns how many were added.
  Future<int> applyRecurringRules(Period period) => guard(() async {
    final result = await _api.recurring.recurringApply(periodId: period.id!);
    return result.added;
  });

  // ------------------------------------------------------------- data exchange

  Future<String> exportCsv() => guard(() => _api.transfer.transferExportCsv());

  /// Creates what the file mentions and skips rows that already exist.
  Future<({int imported, int skipped})> importCsv(String csv) =>
      guard(() async {
        // The body is the raw file, not JSON, so it bypasses the typed client.
        final response = await _dio.post<Map<String, dynamic>>(
          '/import/csv',
          data: csv,
          options: Options(contentType: 'text/csv'),
        );
        final result = api.CsvImportResult.fromJson(response.data!);
        return (imported: result.imported, skipped: result.skipped);
      });

  // ----------------------------------------------------------------- migration

  /// Whether the server holds no data yet, so a migration cannot overwrite any.
  Future<bool> isEmpty() => guard(() async {
    final categories = await _api.categories.categoriesList();
    final periods = await _api.periods.periodsList();
    return categories.isEmpty && periods.isEmpty;
  });

  /// Replaces everything on the server with a backup of the offline app.
  Future<void> importLegacy(api.LegacyBackup backup) => guard(
    () => _api.transfer.transferImportLegacy(
      body: api.ImportLegacy(backup: backup),
    ),
  );
}
