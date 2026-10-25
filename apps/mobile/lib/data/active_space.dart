import 'dart:async';

/// The budget the app works in. Every request names it in the `X-Space-Id`
/// header; with none, the server uses the user's personal budget.
class ActiveSpace {
  String? id;

  final _missing = StreamController<void>.broadcast();

  /// Fires when the server says the budget in use does not exist for the user
  /// (they were removed from it, or it was deleted).
  Stream<void> get onMissing => _missing.stream;

  /// Called by the HTTP client when a request for [id] found no such space.
  void missing() => _missing.add(null);
}
