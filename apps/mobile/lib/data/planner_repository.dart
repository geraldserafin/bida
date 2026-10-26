import 'package:bida_api_client/bida_api_client.dart' as api;
import 'package:dio/dio.dart';

import '../models/models.dart';
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

  // ----------------------------------------------------------------- envelopes

  /// Every envelope the user can see, by name.
  Future<List<Envelope>> envelopes() => guard(() async {
    final all = await _api.envelopes.envelopesList();
    return all.map(envelopeFrom).toList();
  });

  Future<Envelope> createEnvelope(Envelope envelope) => guard(
    () async => envelopeFrom(
      await _api.envelopes.envelopesCreate(body: createEnvelopeOf(envelope)),
    ),
  );

  Future<Envelope> updateEnvelope(Envelope envelope) => guard(
    () async => envelopeFrom(
      await _api.envelopes.envelopesUpdate(
        id: envelope.id!,
        body: updateEnvelopeOf(envelope),
      ),
    ),
  );

  /// Deletes the envelope with its sub-envelopes, expenses and allocations.
  Future<void> deleteEnvelope(String id) =>
      guard(() => _api.envelopes.envelopesDelete(id: id));

  // ------------------------------------------------------------------ overview

  /// The user's money over [month], with the figures of every envelope that is
  /// in [envelopes] (the others are left out).
  Future<Overview> overview(
    BudgetMonth month,
    Map<String, Envelope> envelopes,
  ) => guard(() async {
    final o = await _api.overview.overviewGet(
      from: formatDay(month.from),
      to: formatDay(month.to),
    );
    return Overview(
      month: month,
      income: fromMinor(o.incomeMinor),
      allocated: fromMinor(o.allocatedMinor),
      spent: fromMinor(o.spentMinor),
      pool: fromMinor(o.poolMinor),
      envelopes: [
        for (final f in o.envelopes)
          if (envelopes[f.envelopeId] case final envelope?)
            progressFrom(f, envelope),
      ],
    );
  });

  /// Every month with something in it, newest first.
  Future<List<MonthSummary>> months({int firstDay = 1}) => guard(() async {
    final all = await _api.overview.overviewMonths(startDay: '$firstDay');
    return [
      for (final m in all)
        MonthSummary(
          month: BudgetMonth(parseDay(m.from), parseDay(m.to)),
          income: fromMinor(m.incomeMinor),
          allocated: fromMinor(m.allocatedMinor),
          spent: fromMinor(m.spentMinor),
        ),
    ];
  });

  // ------------------------------------------------------------------- incomes

  /// Newest first. Both days are included.
  Future<List<Income>> incomes({DateTime? from, DateTime? to}) =>
      guard(() async {
        final all = await _api.incomes.incomesList(
          from: from == null ? null : formatDay(from),
          to: to == null ? null : formatDay(to),
        );
        return all.map(incomeFrom).toList();
      });

  Future<Income> saveIncome(Income income) => guard(() async {
    final saved = income.id == null
        ? await _api.incomes.incomesCreate(body: saveIncomeOf(income))
        : await _api.incomes.incomesUpdate(
            id: income.id!,
            body: saveIncomeOf(income),
          );
    return incomeFrom(saved);
  });

  Future<void> deleteIncome(String id) =>
      guard(() => _api.incomes.incomesDelete(id: id));

  // --------------------------------------------------------------- allocations

  /// What was put into the envelope (and, for a top-level one, its
  /// sub-envelopes), newest first.
  Future<List<Allocation>> allocations({String? envelopeId}) => guard(() async {
    final all = await _api.allocations.allocationsList(envelopeId: envelopeId);
    return all.map(allocationFrom).toList();
  });

  /// Puts money into an envelope, or takes it out when the amount is negative.
  /// Throws an [ApiException] tagged `NotEnoughMoney` when it cannot.
  Future<Allocation> saveAllocation(Allocation allocation) => guard(() async {
    final saved = allocation.id == null
        ? await _api.allocations.allocationsCreate(
            body: createAllocationOf(allocation),
          )
        : await _api.allocations.allocationsUpdate(
            id: allocation.id!,
            body: updateAllocationOf(allocation),
          );
    return allocationFrom(saved);
  });

  Future<void> deleteAllocation(String id) =>
      guard(() => _api.allocations.allocationsDelete(id: id));

  // ------------------------------------------------------------------ expenses

  /// Expenses between the two days (both included), newest first.
  /// [envelopeId] narrows it to one envelope and its sub-envelopes.
  Future<List<Expense>> expenses({
    BudgetMonth? month,
    String? envelopeId,
  }) => guard(() async {
    // the days are local, the API wants instants: from the start of the first
    // to the start of the day after the last
    final from = month?.from.toUtc().toIso8601String();
    final to = month == null
        ? null
        : DateTime(
            month.to.year,
            month.to.month,
            month.to.day + 1,
          ).toUtc().toIso8601String();
    final all = <Expense>[];
    for (var offset = 0; ; offset += pageSize) {
      final page = await _api.expenses.expensesList(
        envelopeId: envelopeId,
        from: from,
        to: to,
        limit: '$pageSize',
        offset: '$offset',
      );
      all.addAll(page.map(expenseFrom));
      if (page.length < pageSize) return all;
    }
  });

  /// The expenses of [month] joined with their envelope, newest first.
  Future<List<Transaction>> transactions(
    BudgetMonth month,
    Map<String, Envelope> envelopes,
  ) async {
    final all = await expenses(month: month);
    return [
      for (final expense in all)
        if (envelopes[expense.envelopeId] case final envelope?)
          Transaction(expense: expense, envelope: envelope),
    ];
  }

  Future<Expense> createExpense(Expense expense) => guard(
    () async => expenseFrom(
      await _api.expenses.expensesCreate(body: createExpenseOf(expense)),
    ),
  );

  Future<Expense> updateExpense(Expense expense) => guard(
    () async => expenseFrom(
      await _api.expenses.expensesUpdate(
        id: expense.id!,
        body: updateExpenseOf(expense),
      ),
    ),
  );

  Future<void> deleteExpense(String id) =>
      guard(() => _api.expenses.expensesDelete(id: id));

  // ------------------------------------------------------------------- sharing

  /// The people who share the envelope (its parent's, for a sub-envelope).
  Future<List<Member>> members(String envelopeId) => guard(() async {
    final all = await _api.members.membersList(id: envelopeId);
    return all.map(memberFrom).toList();
  });

  Future<void> setRole(String envelopeId, String userId, EnvelopeRole role) =>
      guard(
        () => _api.members.membersSetRole(
          id: envelopeId,
          userId: userId,
          body: api.SetRole(role: roleOf(role)),
        ),
      );

  /// Removes a member; removing yourself is leaving the envelope.
  Future<void> removeMember(String envelopeId, String userId) =>
      guard(() => _api.members.membersRemove(id: envelopeId, userId: userId));

  /// Who put how much into the envelope and its sub-envelopes.
  Future<List<Contribution>> contributions(String envelopeId) =>
      guard(() async {
        final all = await _api.members.membersContributions(id: envelopeId);
        return all.map(contributionFrom).toList();
      });

  Future<Invitation> invite(
    String envelopeId, {
    required String email,
    required EnvelopeRole role,
  }) => guard(
    () async => invitationFrom(
      await _api.invitations.invitationsInvite(
        id: envelopeId,
        body: api.Invite(email: email, role: roleOf(role)),
      ),
    ),
  );

  /// The invitations of the envelope that wait for an answer or for approval.
  Future<List<Invitation>> envelopeInvitations(String envelopeId) => guard(
    () async {
      final all = await _api.invitations.invitationsForEnvelope(id: envelopeId);
      return all.map(invitationFrom).toList();
    },
  );

  Future<void> revokeInvitation(String envelopeId, String invitationId) =>
      guard(
        () => _api.invitations.invitationsRevoke(
          id: envelopeId,
          invitationId: invitationId,
        ),
      );

  /// Lets in somebody who accepted an invitation.
  Future<void> approveInvitation(String envelopeId, String invitationId) =>
      guard(
        () => _api.invitations.invitationsApprove(
          id: envelopeId,
          invitationId: invitationId,
        ),
      );

  /// The invitations for the address of the user that wait for an answer.
  Future<List<Invitation>> myInvitations() => guard(() async {
    final all = await _api.invitations.invitationsMine();
    return all.map(invitationFrom).toList();
  });

  Future<void> acceptInvitation(String invitationId) => guard(
    () => _api.invitations.invitationsAccept(invitationId: invitationId),
  );

  Future<void> declineInvitation(String invitationId) => guard(
    () => _api.invitations.invitationsDecline(invitationId: invitationId),
  );

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

  /// Adds what every active rule not applied to the month yet makes: the
  /// recurring incomes, then the allocations, then the expenses.
  Future<ApplyOutcome> applyRecurringRules(BudgetMonth month) =>
      guard(() async {
        final result = await _api.recurring.recurringApply(
          body: api.ApplyRecurring(
            from: formatDay(month.from),
            to: formatDay(month.to),
          ),
        );
        return outcomeFrom(result);
      });

  /// What applying the rules to the month would add. Changes nothing.
  Future<ApplyOutcome> pendingRecurring(BudgetMonth month) => guard(() async {
    final result = await _api.recurring.recurringPending(
      from: formatDay(month.from),
      to: formatDay(month.to),
    );
    return outcomeFrom(result);
  });

  Future<List<RecurringIncome>> recurringIncomes() => guard(() async {
    final all = await _api.recurringIncomes.recurringIncomesList();
    return all.map(recurringIncomeFrom).toList();
  });

  Future<void> saveRecurringIncome(RecurringIncome rule) => guard(() async {
    if (rule.id == null) {
      await _api.recurringIncomes.recurringIncomesCreate(
        body: saveRecurringIncomeOf(rule),
      );
    } else {
      await _api.recurringIncomes.recurringIncomesUpdate(
        id: rule.id!,
        body: saveRecurringIncomeOf(rule),
      );
    }
  });

  Future<void> deleteRecurringIncome(String id) =>
      guard(() => _api.recurringIncomes.recurringIncomesDelete(id: id));

  Future<List<AllocationRule>> allocationRules() => guard(() async {
    final all = await _api.allocationRules.allocationRulesList();
    return all.map(allocationRuleFrom).toList();
  });

  Future<void> saveAllocationRule(AllocationRule rule) => guard(() async {
    if (rule.id == null) {
      await _api.allocationRules.allocationRulesCreate(
        body: saveAllocationRuleOf(rule),
      );
    } else {
      await _api.allocationRules.allocationRulesUpdate(
        id: rule.id!,
        body: saveAllocationRuleOf(rule),
      );
    }
  });

  Future<void> deleteAllocationRule(String id) =>
      guard(() => _api.allocationRules.allocationRulesDelete(id: id));

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
    final envelopes = await _api.envelopes.envelopesList();
    final incomes = await _api.incomes.incomesList();
    return envelopes.isEmpty && incomes.isEmpty;
  });

  /// Replaces everything on the server with a backup of the offline app.
  Future<void> importLegacy(api.LegacyBackup backup) => guard(
    () => _api.transfer.transferImportLegacy(
      body: api.ImportLegacy(backup: backup),
    ),
  );
}
