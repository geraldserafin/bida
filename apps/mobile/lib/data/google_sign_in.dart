import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// OAuth client id of the *web* application in the Google Cloud project, set
/// with `--dart-define=GOOGLE_CLIENT_ID=...`. The server checks ID tokens
/// against it; on Android it is also what makes Google issue an ID token.
/// Without it signing in with Google is not offered.
const googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');

bool get googleSignInConfigured => googleClientId.isNotEmpty;

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
