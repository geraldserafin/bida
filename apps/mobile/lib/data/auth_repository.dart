import 'package:bida_api_client/bida_api_client.dart' as api;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_exception.dart';
import 'google_credential.dart';
import 'session_store.dart';

/// Signing in and out, in the app's own terms. Every method either returns or
/// throws an [ApiException].
class AuthRepository {
  AuthRepository(Dio dio, this.session, {api.Transport? transport})
    : _api = api.BidaApi(dio),
      _transport =
          transport ?? (kIsWeb ? api.Transport.cookie : api.Transport.token);

  final api.BidaApi _api;
  final api.Transport _transport;
  final SessionStore session;

  /// E-mails a link and a code to the address.
  Future<void> requestLink(String email) => guard(
    () => _api.auth.authRequestLink(body: api.RequestLink(email: email)),
  );

  /// Returns the e-mail of the signed-in user.
  Future<String> signInWithCode(String email, String code) => guard(() async {
    final result = await _api.auth.authVerifyCode(
      body: api.VerifyCode(email: email, code: code, transport: _transport),
    );
    return _keep(result);
  });

  /// Signs in with what Google gave the app.
  Future<String> signInWithGoogle(
    GoogleCredential credential,
  ) => guard(() async {
    final result = switch (credential) {
      GoogleIdToken(:final token) => await _api.auth.authGoogleSignIn(
        body: api.GoogleSignIn(idToken: token, transport: _transport),
      ),
      GoogleAccessToken(:final token) => await _api.auth.authGoogleAccessToken(
        body: api.GoogleAccessToken(accessToken: token, transport: _transport),
      ),
    };
    return _keep(result);
  });

  /// Signs in with the token of the link from the e-mail.
  Future<String> signInWithLinkToken(String token) => guard(() async {
    final result = await _api.auth.authVerifyToken(
      body: api.VerifyToken(token: token, transport: _transport),
    );
    return _keep(result);
  });

  Future<String> _keep(api.AuthResult result) async {
    final token = result.token;
    if (token != null) await session.save(token);
    return result.user.email;
  }

  /// The e-mail of the user this device is signed in as, or null when it is not.
  Future<String?> currentUser() async {
    try {
      return (await guard(() => _api.auth.authMe())).email;
    } on ApiException catch (error) {
      if (error.failure == ApiFailure.unauthorized) return null;
      rethrow;
    }
  }

  /// Sets the name other members of a shared budget see.
  Future<void> rename(String name) =>
      guard(() => _api.auth.authRename(body: api.SaveProfile(name: name)));

  /// Ends the session. The device is signed out even when the server cannot
  /// be reached.
  Future<void> signOut() async {
    try {
      await guard(() => _api.auth.authLogout());
    } on ApiException {
      // the token is dropped below either way
    }
    await session.clear();
  }

  /// Forgets the session the server already ended.
  Future<void> forget() => session.clear();
}
