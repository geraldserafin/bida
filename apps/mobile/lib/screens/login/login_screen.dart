import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/api_exception.dart';
import '../../data/google_credential.dart';
import '../../data/google_sign_in.dart';
import '../../l10n/app_localizations.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../../util/api_errors.dart';
import '../../widgets/app_button.dart';
import '../../widgets/google_button.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/logo_box.dart';

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// Signing in without a password: the user gets a code (and a link) by e-mail
/// and types the code here, or continues with Google. Either way they first
/// accept how their data is processed.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const emailFieldKey = Key('login-email');
  static const codeFieldKey = Key('login-code');
  static const consentKey = Key('login-consent');

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  /// The address a code was sent to; null while the address is being asked.
  String? _sentTo;
  bool _consent = false;
  bool _busy = false;
  String? _error;

  /// Google sign-ins that came back without signing the user in. After a few
  /// the button is turned off, so nobody keeps trying something that does not
  /// work, and the e-mail code is offered instead.
  int _googleFailures = 0;
  static const _googleAttempts = 3;
  bool get _googleGaveUp => _googleFailures >= _googleAttempts;

  @override
  void initState() {
    super.initState();
    _restorePendingCode();
  }

  /// Back on the code step when a code was sent shortly before: the user went
  /// to their mail for it and Android closed the app meanwhile.
  Future<void> _restorePendingCode() async {
    final email = await context.read<AuthState>().pendingCodeEmail();
    if (email == null || !mounted || _sentTo != null) return;
    setState(() {
      _emailController.text = email;
      _sentTo = email;
      // a code is only sent once the consent is given
      _consent = true;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  /// False, with the reason under the form, until the consent is ticked.
  bool _consented() {
    if (_consent) return true;
    setState(() => _error = AppLocalizations.of(context).consentRequired);
    return false;
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
    // sending again needs no code yet, and the address was checked before
    if (_sentTo == null && !_formKey.currentState!.validate()) return;
    if (!_consented()) return;
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
    if (!_formKey.currentState!.validate() || !_consented()) return;
    final auth = context.read<AuthState>();
    final email = _sentTo!;
    final code = _codeController.text.trim();
    // on success the gate swaps this screen for the planner
    await _run(() => auth.signInWithCode(email, code));
  }

  Future<void> _signInWithGoogle() async {
    if (_busy || _googleGaveUp || !_consented()) return;
    final l10n = AppLocalizations.of(context);
    final auth = context.read<AuthState>();
    setState(() {
      _busy = true;
      _error = null;
    });
    GoogleCredential? credential;
    String? problem;
    try {
      credential = await signInToGoogle();
      // the window closed without an account: say so instead of nothing
      if (credential == null) problem = l10n.googleSignInNoAccount;
    } on GoogleSignInFailed {
      problem = l10n.googleSignInFailed;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    final signedIn =
        credential != null &&
        await _run(() => auth.signInWithGoogle(credential!));
    if (signedIn || !mounted) return;
    setState(() {
      _googleFailures++;
      if (_googleGaveUp) {
        _error = l10n.googleSignInGaveUp;
      } else if (problem != null) {
        _error = problem;
      }
    });
  }

  void _useOtherEmail() {
    context.read<AuthState>().forgetPendingCode();
    setState(() {
      _sentTo = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = AppColors.of(context);
    final sentTo = _sentTo;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 32),
            child: ConstrainedBox(
              // fill the screen so the buttons sit at the bottom
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 84,
              ),
              child: IntrinsicHeight(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: LogoBox(),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l10n.loginHeadline,
                        style: theme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        sentTo == null
                            ? l10n.loginSubtitle
                            : l10n.codeSentTo(sentTo),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: c.textMuted,
                        ),
                      ),
                      const SizedBox(height: 24),
                      LabeledField(
                        fieldKey: LoginScreen.emailFieldKey,
                        label: l10n.emailAddress,
                        controller: _emailController,
                        enabled: sentTo == null && !_busy,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.done,
                        autofocus: true,
                        validator: (v) =>
                            _emailPattern.hasMatch((v ?? '').trim())
                            ? null
                            : l10n.enterValidEmail,
                        onSubmitted: (_) => _sendCode(),
                      ),
                      if (sentTo != null) ..._codePart(l10n, c),
                      const SizedBox(height: 24),
                      _Consent(
                        value: _consent,
                        onChanged: (v) => setState(() {
                          _consent = v;
                          if (v && _error == l10n.consentRequired) {
                            _error = null;
                          }
                        }),
                      ),
                      const Spacer(),
                      const SizedBox(height: 24),
                      AppButton(
                        label: sentTo == null
                            ? l10n.sendCode
                            : l10n.signInAction,
                        busy: _busy,
                        onPressed: sentTo == null ? _sendCode : _signIn,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: TextStyle(color: c.danger, fontSize: 14),
                        ),
                      ],
                      if (googleSignInConfigured && sentTo == null) ...[
                        const SizedBox(height: 24),
                        _OrDivider(label: l10n.orSeparator),
                        const SizedBox(height: 24),
                        GoogleButton(
                          label: l10n.signInWithGoogle,
                          onPressed: _busy || _googleGaveUp
                              ? null
                              : _signInWithGoogle,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _codePart(AppLocalizations l10n, AppColors c) {
    final caption = Theme.of(context).textTheme.bodySmall;
    final link = caption?.copyWith(
      color: c.text,
      decoration: TextDecoration.underline,
      decorationColor: c.textMuted,
    );
    return [
      const SizedBox(height: 24),
      LabeledField(
        fieldKey: LoginScreen.codeFieldKey,
        label: l10n.codeFieldLabel,
        controller: _codeController,
        keyboardType: TextInputType.number,
        autofillHints: const [AutofillHints.oneTimeCode],
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        autofocus: true,
        validator: (v) => (v ?? '').trim().length == 6 ? null : l10n.enterCode,
        onSubmitted: (_) => _signIn(),
      ),
      const SizedBox(height: 24),
      Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          Text(l10n.codeValidity, style: caption),
          GestureDetector(
            onTap: _busy ? null : _sendCode,
            child: Text(l10n.resendShort, style: link),
          ),
          Text('·', style: caption),
          GestureDetector(
            onTap: _busy ? null : _useOtherEmail,
            child: Text(l10n.useOtherEmail, style: link),
          ),
        ],
      ),
    ];
  }
}

/// The data-processing consent ("Zgoda RODO").
class _Consent extends StatelessWidget {
  const _Consent({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              key: LoginScreen.consentKey,
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.consent,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppColors.of(context).textSoft,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        Expanded(child: Divider(height: 1, color: c.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(child: Divider(height: 1, color: c.border)),
      ],
    );
  }
}
