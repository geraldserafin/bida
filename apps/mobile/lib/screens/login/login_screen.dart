import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/api_exception.dart';
import '../../data/google_credential.dart';
import '../../data/google_sign_in.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_state.dart';
import '../../widgets/google_button.dart';
import '../../util/api_errors.dart';

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// Signing in without a password: the user gets a code (and a link) by e-mail
/// and types the code here.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _emailKey = GlobalKey<FormState>();
  final _codeKey = GlobalKey<FormState>();

  /// The address a code was sent to; null while the address is being asked.
  String? _sentTo;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  /// Runs [action]; an error of the server becomes the text under the form.
  Future<bool> _run(Future<void> Function() action) async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      return true;
    } on ApiException catch (error) {
      if (!mounted) return false;
      setState(
        () => _error = error.tag == 'InvalidLogin'
            ? l10n.invalidCode
            : apiErrorMessage(l10n, error),
      );
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode() async {
    if (!_emailKey.currentState!.validate()) return;
    final auth = context.read<AuthState>();
    final email = _emailController.text.trim();
    final sent = await _run(() => auth.requestLink(email));
    if (sent && mounted) {
      setState(() {
        _sentTo = email;
        _codeController.clear();
      });
    }
  }

  Future<void> _signIn() async {
    if (!_codeKey.currentState!.validate()) return;
    final auth = context.read<AuthState>();
    final email = _sentTo!;
    final code = _codeController.text.trim();
    // on success the gate swaps this screen for the planner
    await _run(() => auth.signInWithCode(email, code));
  }

  Future<void> _signInWithGoogle() async {
    final l10n = AppLocalizations.of(context);
    final auth = context.read<AuthState>();
    final GoogleCredential? credential;
    try {
      credential = await signInToGoogle();
    } on GoogleSignInFailed {
      if (mounted) setState(() => _error = l10n.googleSignInFailed);
      return;
    }
    // null: the user closed Google's window
    if (credential == null || !mounted) return;
    await _run(() => auth.signInWithGoogle(credential!));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sentTo = _sentTo;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.signInTitle, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    sentTo == null
                        ? l10n.signInSubtitle
                        : l10n.codeSentTo(sentTo),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (sentTo == null) ...[
                    if (googleSignInConfigured) ...[
                      GoogleButton(
                        label: l10n.signInWithGoogle,
                        onPressed: _busy ? null : _signInWithGoogle,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(l10n.orSeparator),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    _emailForm(l10n),
                  ] else
                    _codeForm(l10n),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emailForm(AppLocalizations l10n) {
    return Form(
      key: _emailKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.done,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.emailAddress,
              border: const OutlineInputBorder(),
            ),
            validator: (v) => _emailPattern.hasMatch((v ?? '').trim())
                ? null
                : l10n.enterValidEmail,
            onFieldSubmitted: (_) => _sendCode(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _sendCode,
            child: _busy ? const _Spinner() : Text(l10n.sendCode),
          ),
        ],
      ),
    );
  }

  Widget _codeForm(AppLocalizations l10n) {
    return Form(
      key: _codeKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 8),
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.signInCode,
              border: const OutlineInputBorder(),
            ),
            validator: (v) =>
                (v ?? '').trim().length == 6 ? null : l10n.enterCode,
            onFieldSubmitted: (_) => _signIn(),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : _signIn,
            child: _busy ? const _Spinner() : Text(l10n.signInAction),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy ? null : _sendCode,
            child: Text(l10n.resendCode),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () => setState(() {
                    _sentTo = null;
                    _error = null;
                  }),
            child: Text(l10n.useOtherEmail),
          ),
        ],
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: 18,
    height: 18,
    child: CircularProgressIndicator(strokeWidth: 2),
  );
}
