import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

/// "Sign in with Google" in a browser: the button is drawn by Google's own
/// script, and the ID token arrives as an event once the user has signed in.
class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({
    super.key,
    required this.onIdToken,
    this.enabled = true,
  });

  final void Function(String idToken) onIdToken;
  final bool enabled;

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  StreamSubscription<GoogleSignInAuthenticationEvent>? _events;

  @override
  void initState() {
    super.initState();
    _events = GoogleSignIn.instance.authenticationEvents.listen((event) {
      if (event is! GoogleSignInAuthenticationEventSignIn) return;
      final idToken = event.user.authentication.idToken;
      if (idToken != null && widget.enabled) widget.onIdToken(idToken);
    }, onError: (Object _) {});
  }

  @override
  void dispose() {
    _events?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Google draws the button itself and takes a width of 200 to 400
        final width = constraints.maxWidth.clamp(200.0, 400.0);
        return SizedBox(
          height: 44,
          // rounded like the app's own buttons
          child: ClipRRect(
            // the button is drawn once, so a new look needs a new widget
            key: ValueKey('$dark-$width'),
            borderRadius: BorderRadius.circular(12),
            child: web.renderButton(
              configuration: web.GSIButtonConfiguration(
                type: web.GSIButtonType.standard,
                theme: dark
                    ? web.GSIButtonTheme.filledBlack
                    : web.GSIButtonTheme.outline,
                size: web.GSIButtonSize.large,
                text: web.GSIButtonText.signinWith,
                shape: web.GSIButtonShape.rectangular,
                locale: 'pl',
                minimumWidth: width,
              ),
            ),
          ),
        );
      },
    );
  }
}
