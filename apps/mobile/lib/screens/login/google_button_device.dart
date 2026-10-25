import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../l10n/app_localizations.dart';

/// "Sign in with Google" on Android and iOS: opens Google's account chooser
/// and hands over the ID token of the account picked. A cancelled chooser is
/// not an error.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onIdToken,
    this.enabled = true,
  });

  final void Function(String idToken) onIdToken;
  final bool enabled;

  Future<void> _signIn(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken != null) onIdToken(idToken);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled ||
          error.code == GoogleSignInExceptionCode.interrupted) {
        return;
      }
      messenger.showSnackBar(SnackBar(content: Text(l10n.googleSignInFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OutlinedButton.icon(
      onPressed: enabled ? () => _signIn(context) : null,
      icon: const Icon(Icons.g_mobiledata, size: 28),
      label: Text(l10n.signInWithGoogle),
    );
  }
}
