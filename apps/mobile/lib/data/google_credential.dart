/// What Google gave the app to prove who signed in. The server accepts both.
sealed class GoogleCredential {
  const GoogleCredential(this.token);

  final String token;
}

/// An ID token, which Android and iOS get from Google sign-in.
class GoogleIdToken extends GoogleCredential {
  const GoogleIdToken(super.token);
}

/// An access token, which a browser gets from Google's sign-in popup.
class GoogleAccessToken extends GoogleCredential {
  const GoogleAccessToken(super.token);
}
