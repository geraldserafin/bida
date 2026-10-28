import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  AuthState(
    this._repo, {
    FlutterSecureStorage? storage,
    DateTime Function()? clock,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _clock = clock ?? DateTime.now {
    // the server ended the session behind our back
    _expired = _repo.session.onExpired.listen((_) => _signedOut());
  }

  final AuthRepository _repo;
  final FlutterSecureStorage _storage;
  final DateTime Function() _clock;

  static const _kCodeEmail = 'login_code_email';
  static const _kCodeSentAt = 'login_code_sent_at';

  /// How long an e-mailed code works.
  static const codeValidity = Duration(minutes: 15);
  late final StreamSubscription<void> _expired;

  AuthStatus _status = AuthStatus.unknown;
  AuthStatus get status => _status;
  bool get isSignedIn => _status == AuthStatus.signedIn;

  String? _email;
  String? get email => _email;

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

  /// E-mails the address a code, and remembers where it went: the user goes
  /// to their mail app for it, and Android may close this one meanwhile.
  /// Throws [ApiException].
  Future<void> requestLink(String email) async {
    await _repo.requestLink(email);
    await _storage.write(key: _kCodeEmail, value: email);
    await _storage.write(
      key: _kCodeSentAt,
      value: _clock().toUtc().toIso8601String(),
    );
  }

  /// The address the last code went to while that code still works, so the
  /// sign-in screen can ask for it again after the app was closed.
  Future<String?> pendingCodeEmail() async {
    try {
      final email = await _storage.read(key: _kCodeEmail);
      final sentAt = DateTime.tryParse(
        await _storage.read(key: _kCodeSentAt) ?? '',
      );
      if (email == null || sentAt == null) return null;
      if (_clock().difference(sentAt) > codeValidity) {
        await forgetPendingCode();
        return null;
      }
      return email;
    } on Object catch (error) {
      // only a convenience: without it the user asks for a new code
      debugPrint('pending sign-in code unreadable: $error');
      return null;
    }
  }

  Future<void> forgetPendingCode() async {
    await _storage.delete(key: _kCodeEmail);
    await _storage.delete(key: _kCodeSentAt);
  }

  /// Throws [ApiException]; a wrong code has the tag `InvalidLogin`.
  Future<void> signInWithCode(String email, String code) async {
    _email = await _repo.signInWithCode(email, code);
    await forgetPendingCode();
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
