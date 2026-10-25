import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';

/// Full-screen unlock gate shown on launch and resume when a PIN is set.
class LockScreen extends StatefulWidget {
  const LockScreen({
    super.key,
    required this.auth,
    required this.onUnlocked,
    this.onBiometricStart,
    this.onBiometricEnd,
  });

  final AuthService auth;
  final VoidCallback onUnlocked;

  /// Called around a biometric prompt so the host can ignore the
  /// pause/resume it triggers (which would otherwise re-lock the app).
  final VoidCallback? onBiometricStart;
  final VoidCallback? onBiometricEnd;

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _controller = TextEditingController();
  bool _error = false;

  /// Only true when the user has actually turned biometric unlock ON in
  /// Settings (and the device supports it). Never offer it otherwise.
  bool _biometricOffered = false;

  @override
  void initState() {
    super.initState();
    // Run after the first frame so the native window is shown and focused —
    // otherwise the OS (e.g. Windows Hello) won't display its prompt.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeStartBiometric());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _maybeStartBiometric() async {
    final enabled = await widget.auth.isBiometricEnabled();
    final available = enabled && await widget.auth.canUseBiometrics();
    if (!mounted) return;
    setState(() => _biometricOffered = available);
    if (available) _authenticateBiometric();
  }

  Future<void> _authenticateBiometric() async {
    final l10n = AppLocalizations.of(context);
    widget.onBiometricStart?.call();
    final ok = await widget.auth.authenticateBiometric(l10n.biometricReason);
    widget.onBiometricEnd?.call();
    if (ok && mounted) widget.onUnlocked();
  }

  Future<void> _submit() async {
    final ok = await widget.auth.verifyPin(_controller.text);
    if (!mounted) return;
    if (ok) {
      widget.onUnlocked();
    } else {
      setState(() => _error = true);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 56, color: scheme.primary),
                const SizedBox(height: 16),
                Text(
                  l10n.unlockTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) {
                    if (_error) setState(() => _error = false);
                  },
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    errorText: _error ? l10n.wrongPin : null,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    child: Text(l10n.unlock),
                  ),
                ),
                if (_biometricOffered) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _authenticateBiometric,
                    icon: const Icon(Icons.fingerprint),
                    label: Text(l10n.useBiometrics),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
