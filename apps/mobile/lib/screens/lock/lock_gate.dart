import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'lock_screen.dart';

/// Wraps the app and enforces the PIN lock on launch and whenever the app is
/// resumed from the background.
class LockGate extends StatefulWidget {
  const LockGate({super.key, required this.child});

  final Widget child;

  @override
  State<LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<LockGate> with WidgetsBindingObserver {
  final AuthService _auth = AuthService();

  bool _initializing = true;
  bool _hasPin = false;
  bool _locked = false;

  /// While a biometric prompt is up the OS backgrounds us; ignore the
  /// resulting lifecycle events so we don't immediately re-lock.
  bool _authInProgress = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _init() async {
    final hasPin = await _auth.hasPin();
    if (!mounted) return;
    setState(() {
      _hasPin = hasPin;
      _locked = hasPin;
      _initializing = false;
    });
  }

  /// True once the app has been genuinely backgrounded (minimized/hidden), so
  /// we don't re-lock on a mere focus change (alt-tab) on desktop.
  bool _wasBackgrounded = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_authInProgress) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _wasBackgrounded = true;
    } else if (state == AppLifecycleState.resumed) {
      final wasBackgrounded = _wasBackgrounded;
      _wasBackgrounded = false;
      // Re-check on resume: a PIN may have been set/cleared in Settings.
      _auth.hasPin().then((hasPin) {
        if (!mounted) return;
        setState(() {
          _hasPin = hasPin;
          if (hasPin && wasBackgrounded) _locked = true;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const SizedBox.shrink();
    }
    if (!_hasPin || !_locked) {
      return widget.child;
    }
    return LockScreen(
      auth: _auth,
      onUnlocked: () => setState(() => _locked = false),
      onBiometricStart: () => _authInProgress = true,
      onBiometricEnd: () => _authInProgress = false,
    );
  }
}
