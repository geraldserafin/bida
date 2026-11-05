import 'dart:async';

import 'package:flutter/material.dart';

import '../data/api_exception.dart';
import '../data/budget_repository.dart';
import '../models/models.dart';
import 'app_settings.dart';

/// App-wide state: the wallet, the households, the to-do list and the
/// household on screen with its piggy bank.
///
/// Every start runs the app start of the server first (`sync`): nothing
/// happens on the server in the background. The app needs the server, so a
/// failed request surfaces as [loadError] while loading, and as an
/// [ApiException] thrown from the method that was called otherwise.
class BudgetState extends ChangeNotifier {
  BudgetState({
    required this.repository,
    required this.settings,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// For screens that read something only they show (history, the log).
  final BudgetRepository repository;

  /// Where the household on screen and the dashboard range are kept.
  final AppSettings settings;
  final DateTime Function() _clock;

  bool _loading = true;
  bool get isLoading => _loading;

  ApiException? _loadError;
  ApiException? get loadError => _loadError;

  bool _signedIn = false;

  /// Bumps on every refresh, so widgets that load their own data reload.
  int _version = 0;
  int get version => _version;

  List<Household> _households = const [];
  List<Household> get households => _households;

  Overview? _overview;
  Overview? get overview => _overview;

  Wallet get wallet =>
      _overview?.wallet ?? const Wallet(balanceMinor: 0, unconfirmedMinor: 0);

  List<TodoItem> _todo = const [];

  /// The to-do list (F34); its length is the badge.
  List<TodoItem> get todo => _todo;

  List<ClosedSummary> _unseen = const [];

  /// Closed periods to show once (F35).
  List<ClosedSummary> get unseenSummaries => _unseen;

  List<Invitation> _invitations = const [];
  List<Invitation> get invitations => _invitations;

  /// The household on screen: the one chosen last, or the first.
  Household? get household {
    if (_households.isEmpty) return null;
    final id = settings.householdId;
    return _households.where((h) => h.id == id).firstOrNull ??
        _households.first;
  }

  String? _periodId;

  /// The period on screen: the current one unless another was chosen.
  Period? get period {
    final h = household;
    if (h == null) return null;
    if (_periodId == h.next?.id) return h.next;
    return h.current;
  }

  PeriodSummary? _summary;
  PeriodSummary? get summary => _summary;

  List<Envelope> _envelopes = const [];

  /// Of the household on screen, archived ones too.
  List<Envelope> get envelopes => _envelopes;
  List<Envelope> get activeEnvelopes => [
    for (final e in _envelopes)
      if (!e.archived) e,
  ];

  Envelope? envelopeById(String? id) =>
      _envelopes.where((e) => e.id == id).firstOrNull;

  List<Member> _members = const [];
  List<Member> get members => _members;

  /// The days the dashboard shows the households over (F38).
  DateTimeRange get dashboardRange {
    final now = _clock();
    switch (settings.dashboardRange) {
      case DashboardRange.custom:
        final custom = settings.customRange;
        if (custom != null) return custom;
      case DashboardRange.period:
        final current = household?.current;
        if (current != null) {
          return DateTimeRange(start: current.startsOn, end: current.endsOn);
        }
      case DashboardRange.month:
        break;
    }
    return DateTimeRange(
      start: DateTime(now.year, now.month),
      end: DateTime(now.year, now.month + 1, 0),
    );
  }

  /// Loads everything once somebody signs in, forgets it on sign-out.
  void signedIn(bool signedIn) {
    if (signedIn == _signedIn) return;
    _signedIn = signedIn;
    if (signedIn) {
      unawaited(load());
    } else {
      _households = const [];
      _overview = null;
      _todo = const [];
      _unseen = const [];
      _summary = null;
      _loading = true;
      notifyListeners();
    }
  }

  /// The app start: what is due on the server, then all the data.
  Future<void> load() async {
    _loading = true;
    _loadError = null;
    notifyListeners();
    try {
      final synced = await repository.sync();
      _unseen = synced.summaries;
      await _fetch();
    } on ApiException catch (error) {
      _loadError = error;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await _fetch();
    notifyListeners();
  }

  Future<void> _fetch() async {
    _households = await repository.households();
    final range = dashboardRange;
    _overview = await repository.overview(range.start, range.end);
    _todo = await repository.todo();
    _invitations = await repository.myInvitations();
    final h = household;
    if (h == null) {
      _summary = null;
      _envelopes = const [];
      _members = const [];
    } else {
      final p = period ?? h.current;
      _summary = await repository.periodSummary(p.id);
      _envelopes = await repository.envelopes(h.id);
      _members = await repository.members(h.id);
    }
    _version++;
  }

  Future<void> selectHousehold(String id) async {
    _periodId = null;
    await settings.setHousehold(id);
    await refresh();
  }

  /// Shows the current or the next period of the household.
  Future<void> showPeriod(String? periodId) async {
    _periodId = periodId;
    await refresh();
  }

  Future<void> summarySeen(ClosedSummary summary) async {
    _unseen = [
      for (final s in _unseen)
        if (s.periodId != summary.periodId) s,
    ];
    notifyListeners();
    await repository.markSummarySeen(summary.periodId);
  }

  /// Runs a change and reloads what it may have touched.
  Future<T> change<T>(Future<T> Function(BudgetRepository repo) action) async {
    final result = await action(repository);
    await refresh();
    return result;
  }

  Future<Household> createHousehold({
    required String name,
    Cycle? cycle,
    DateTime? firstEndsOn,
    List<String>? envelopes,
  }) async {
    final created = await repository.createHousehold(
      name: name,
      cycle: cycle,
      firstEndsOn: firstEndsOn,
      envelopes: envelopes,
    );
    await settings.setHousehold(created.id);
    _periodId = null;
    await refresh();
    return created;
  }

  Future<void> deleteHousehold(String id) async {
    await repository.deleteHousehold(id);
    if (settings.householdId == id) await settings.setHousehold(null);
    await refresh();
  }

  Future<void> leaveHousehold(String id, {required bool withdraw}) async {
    await repository.leave(id, withdraw: withdraw);
    if (settings.householdId == id) await settings.setHousehold(null);
    await refresh();
  }

  Future<void> acceptInvitation(String id) async {
    await repository.acceptInvitation(id);
    await refresh();
  }
}
