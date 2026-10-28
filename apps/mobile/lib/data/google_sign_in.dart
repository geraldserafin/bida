import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'google_credential.dart';

/// OAuth client id of the *web* application in the Google Cloud project, set
/// with `--dart-define=GOOGLE_CLIENT_ID=...`. The server checks what Google
/// hands out against it; on Android it is also what makes Google issue an ID
/// token. Without it signing in with Google is not offered.
const googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');

bool get googleSignInConfigured => googleClientId.isNotEmpty;

/// Google could not sign the user in (not because they cancelled).
class GoogleSignInFailed implements Exception {
  const GoogleSignInFailed(this.cause);

  final Object cause;

  @override
  String toString() => 'GoogleSignInFailed($cause)';
}

/// Prepares Google sign-in once at startup. A failure only turns the feature
/// off: the e-mail code still works.
Future<void> initGoogleSignIn() async {
  if (!googleSignInConfigured) return;
  try {
    await GoogleSignIn.instance.initialize(
      clientId: kIsWeb ? googleClientId : null,
      serverClientId: kIsWeb ? null : googleClientId,
    );
  } on Object catch (error) {
    debugPrint('Google sign-in is not available: $error');
  }
}

/// Lets the user pick a Google account. Null when Google comes back without
/// one. That is not always the user cancelling: on Android, Credential Manager
/// reports a client Google does not know (a missing SHA-1) the same way, so
/// the caller should say that nothing happened rather than stay silent. Call
/// it from a tap: a browser only opens the popup for one.
///
/// A browser cannot get an ID token without Google's own button, so there the
/// popup asks for access to the profile and an access token comes back; the
/// server checks it with Google. Devices get the ID token directly.
Future<GoogleCredential?> signInToGoogle() async {
  try {
    if (kIsWeb) {
      final authorization = await GoogleSignIn.instance.authorizationClient
          .authorizeScopes(const ['openid', 'email', 'profile']);
      return GoogleAccessToken(authorization.accessToken);
    }
    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const GoogleSignInFailed('Google returned no ID token');
    }
    return GoogleIdToken(idToken);
  } on GoogleSignInException catch (error) {
    // the description is what tells a cancel from a misconfigured client
    debugPrint('Google sign-in ended: $error');
    if (error.code == GoogleSignInExceptionCode.canceled ||
        error.code == GoogleSignInExceptionCode.interrupted) {
      return null;
    }
    throw GoogleSignInFailed(error);
  }
}

/// Forgets the Google account on this device, so the next sign-in asks which
/// one to use again.
Future<void> signOutOfGoogle() async {
  if (!googleSignInConfigured) return;
  try {
    await GoogleSignIn.instance.signOut();
  } on Object catch (error) {
    debugPrint('Google sign-out failed: $error');
  }
}
