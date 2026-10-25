import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/active_space.dart';
import '../data/api_exception.dart';
import '../data/sharing_repository.dart';
import '../models/models.dart';

/// The errors of the two requests `load` makes side by side.
typedef _Failures = (AsyncError?, AsyncError?);

/// Which budgets the signed-in user has and which one the app works in. The
/// personal budget is the default; the choice is remembered on the device.
class SpacesState extends ChangeNotifier {
  SpacesState(this._repo, this._active, {FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage() {
    // the server says the budget in use is not there any more
    _missing = _active.onMissing.listen((_) => _recoverFromMissing());
  }

  static const _kCurrentSpace = 'current_space_id';

  final SharingRepository _repo;
  final ActiveSpace _active;
  final FlutterSecureStorage _storage;
  late final StreamSubscription<void> _missing;

  bool _signedIn = false;

  List<AppSpace> _spaces = const [];
  List<AppSpace> get spaces => _spaces;

  AppSpace? _current;

  /// The budget the app works in; null until the list is loaded.
  AppSpace? get current => _current;

  /// Invitations to other people's budgets that wait for an answer.
  List<SpaceInvitation> _invitations = const [];
  List<SpaceInvitation> get invitations => _invitations;

  bool _loading = true;
  bool get isLoading => _loading;

  /// Why the list could not be loaded, or null.
  ApiException? _loadError;
  ApiException? get loadError => _loadError;

  /// The name of a budget the user was removed from, to tell them once.
  String? _removedFrom;
  String? get removedFrom => _removedFrom;

  void clearRemovedNotice() {
    if (_removedFrom == null) return;
    _removedFrom = null;
    notifyListeners();
  }

  bool get isOwner => _current?.isOwner ?? false;

  /// Tells the state whether somebody is signed in: it loads their budgets
  /// when they are, and forgets everything when they sign out.
  void bind({required bool signedIn}) {
    if (signedIn == _signedIn) return;
    _signedIn = signedIn;
    // this is called while the widget tree builds, so change state after it
    scheduleMicrotask(() => signedIn ? load() : _forget());
  }

  void _forget() {
    _spaces = const [];
    _current = null;
    _invitations = const [];
    _loadError = null;
    _loading = true;
    _active.id = null;
    notifyListeners();
  }

  /// Fetches the budgets and the open invitations, and picks the one to work
  /// in: the remembered one, else the personal one.
  Future<void> load() async {
    _loading = true;
    _loadError = null;
    notifyListeners();
    try {
      final (spaces, invitations) = await (
        _repo.spaces(),
        _repo.myInvitations(),
      ).wait;
      _spaces = spaces;
      _invitations = invitations;
      final stored = await _storage.read(key: _kCurrentSpace);
      _choose(
        _spaces.where((s) => s.id == stored).firstOrNull ??
            _spaces.where((s) => !s.isShared).firstOrNull ??
            _spaces.firstOrNull,
      );
    } on ApiException catch (error) {
      _loadError = error;
    } on ParallelWaitError<Object?, _Failures> catch (error) {
      // the two requests ran side by side: report the first that failed
      final (a, b) = error.errors;
      _loadError = [a?.error, b?.error].whereType<ApiException>().firstOrNull;
      if (_loadError == null) rethrow;
    }
    _loading = false;
    notifyListeners();
  }

  void _choose(AppSpace? space) {
    _current = space;
    _active.id = space?.id;
  }

  /// Works in another of the user's budgets.
  Future<void> select(String id) async {
    final space = _spaces.where((s) => s.id == id).firstOrNull;
    if (space == null || space.id == _current?.id) return;
    _choose(space);
    await _storage.write(key: _kCurrentSpace, value: id);
    notifyListeners();
  }

  /// Reloads the list after something changed (a rename, somebody joined) and
  /// keeps the current budget when it still exists.
  Future<void> refresh() async {
    try {
      final spaces = await _repo.spaces();
      final invitations = await _repo.myInvitations();
      _spaces = spaces;
      _invitations = invitations;
      final stillThere = _spaces.where((s) => s.id == _current?.id).firstOrNull;
      _choose(stillThere ?? _spaces.where((s) => !s.isShared).firstOrNull);
      notifyListeners();
    } on ApiException {
      // keep what is shown; the next action will report the problem
    }
  }

  /// Creates a shared budget and switches to it.
  Future<void> createShared(String name, String currency) async {
    final created = await _repo.createSpace(name, currency);
    _spaces = [..._spaces, created];
    await select(created.id);
  }

  Future<void> leave(AppSpace space) async {
    await _repo.leaveSpace(space.id);
    await _afterLeaving(space);
  }

  Future<void> delete(AppSpace space) async {
    await _repo.deleteSpace(space.id);
    await _afterLeaving(space);
  }

  Future<void> _afterLeaving(AppSpace space) async {
    _spaces = _spaces.where((s) => s.id != space.id).toList();
    if (_current?.id == space.id) {
      final personal = _spaces.where((s) => !s.isShared).firstOrNull;
      _choose(personal);
      await _storage.delete(key: _kCurrentSpace);
    }
    notifyListeners();
  }

  /// Answers an invitation. Accepting does not let you in yet: an owner of the
  /// budget has to approve it.
  Future<void> answerInvitation(
    SpaceInvitation invitation, {
    required bool accept,
  }) async {
    if (accept) {
      await _repo.acceptInvitation(invitation.id);
    } else {
      await _repo.declineInvitation(invitation.id);
    }
    _invitations = _invitations.where((i) => i.id != invitation.id).toList();
    notifyListeners();
  }

  Future<void> _recoverFromMissing() async {
    final lost = _current;
    if (lost == null) return;
    _removedFrom = lost.name;
    _spaces = _spaces.where((s) => s.id != lost.id).toList();
    _choose(_spaces.where((s) => !s.isShared).firstOrNull);
    await _storage.delete(key: _kCurrentSpace);
    notifyListeners();
    await refresh();
  }

  @override
  void dispose() {
    _missing.cancel();
    super.dispose();
  }
}
