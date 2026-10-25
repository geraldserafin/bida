import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/api_exception.dart';
import '../data/auth_repository.dart';
import '../data/google_credential.dart';

enum AuthStatus {
  /// Not known yet: the server is being asked.
  unknown,
  signedOut,
  signedIn,
}

/// Who is signed in on this device. Decides whether the app shows the sign-in
/// screen or the planner.
class AuthState extends ChangeNotifier {
  AuthState(this._repo) {
    // the server ended the session behind our back
    _expired = _repo.session.onExpired.listen((_) => _signedOut());
  }

  final AuthRepository _repo;
  late final StreamSubscription<void> _expired;

  AuthStatus _status = AuthStatus.unknown;
  AuthStatus get status => _status;
  bool get isSignedIn => _status == AuthStatus.signedIn;

  String? _email;
  String? get email => _email;

  /// What other members of shared budgets see; null until the user sets it.
  String? get name => _repo.name;

  /// Sets the name other members see. Throws [ApiException].
  Future<void> rename(String name) async {
    await _repo.rename(name);
    notifyListeners();
  }

  /// Why the server could not be asked who is signed in, or null.
  ApiException? _restoreError;
  ApiException? get restoreError => _restoreError;

  /// Finds out whether this device is still signed in. In a browser,
  /// [linkToken] is the token of the link the user opened from the e-mail.
  Future<void> restore({String? linkToken}) async {
    _status = AuthStatus.unknown;
    _restoreError = null;
    notifyListeners();
    try {
      if (linkToken != null) {
        try {
          _email = await _repo.signInWithLinkToken(linkToken);
          _status = AuthStatus.signedIn;
          notifyListeners();
          return;
        } on ApiException catch (error) {
          // a used or expired link is no reason to stop: maybe a session exists
          if (error.failure == ApiFailure.unreachable) rethrow;
        }
      }
      _email = await _repo.currentUser();
      _status = _email == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    } on ApiException catch (error) {
      _restoreError = error;
    }
    notifyListeners();
  }

  /// E-mails the address a code. Throws [ApiException].
  Future<void> requestLink(String email) => _repo.requestLink(email);

  /// Throws [ApiException]; a wrong code has the tag `InvalidLogin`.
  Future<void> signInWithCode(String email, String code) async {
    _email = await _repo.signInWithCode(email, code);
    _status = AuthStatus.signedIn;
    notifyListeners();
  }

  /// Throws [ApiException].
  Future<void> signInWithGoogle(GoogleCredential credential) async {
    _email = await _repo.signInWithGoogle(credential);
    _status = AuthStatus.signedIn;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _repo.signOut();
    _signedOut();
  }

  void _signedOut() {
    if (_status == AuthStatus.signedOut) return;
    _repo.forget();
    _email = null;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }

  @override
  void dispose() {
    _expired.cancel();
    super.dispose();
  }
}
