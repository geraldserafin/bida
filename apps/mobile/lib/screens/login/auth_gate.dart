import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_state.dart';
import '../../widgets/error_view.dart';
import 'login_screen.dart';

/// Shows the planner to a signed-in user and the sign-in screen to everyone
/// else.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final error = auth.restoreError;
    if (error != null) {
      return Scaffold(
        body: ErrorView(error: error, onRetry: auth.restore),
      );
    }
    return switch (auth.status) {
      AuthStatus.unknown => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      AuthStatus.signedOut => const LoginScreen(),
      AuthStatus.signedIn => child,
    };
  }
}
