import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/google_sign_in.dart';
import '../../l10n/app_localizations.dart';
import '../../services/auth_service.dart';

import '../../state/app_settings.dart';
import '../../state/auth_state.dart';
import '../../state/budget_state.dart';
import '../../util/money_steps.dart';
import '../wallet/wallet_screen.dart';

/// App settings: general, appearance, security, data.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _auth = AuthService();

  bool _loading = true;
  bool _hasPin = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final hasPin = await _auth.hasPin();
    final available = await _auth.canUseBiometrics();
    final enabled = await _auth.isBiometricEnabled();
    if (!mounted) return;
    setState(() {
      _hasPin = hasPin;
      _biometricAvailable = available;
      _biometricEnabled = enabled;
      _loading = false;
    });
  }

  // ---- security -------------------------------------------------------------

  Future<void> _toggleLock(bool enable) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (enable) {
      final pin = await _showPinSetup();
      if (pin == null) return;
      await _auth.setPin(pin);
      messenger.showSnackBar(SnackBar(content: Text(l10n.pinSaved)));
    } else {
      await _auth.clearPin();
      messenger.showSnackBar(SnackBar(content: Text(l10n.lockDisabled)));
    }
    await _load();
  }

  Future<void> _changePin() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final pin = await _showPinSetup();
    if (pin == null) return;
    await _auth.setPin(pin);
    messenger.showSnackBar(SnackBar(content: Text(l10n.pinSaved)));
  }

  Future<void> _toggleBiometric(bool enabled) async {
    await _auth.setBiometricEnabled(enabled);
    if (mounted) setState(() => _biometricEnabled = enabled);
  }

  Future<String?> _showPinSetup() => showDialog<String>(
    context: context,
    builder: (_) => const _PinSetupDialog(),
  );

  // ---- the dashboard and the account -----------------------------------------

  Future<void> _pickRange(AppSettings settings) async {
    final l10n = AppLocalizations.of(context);
    final state = context.read<BudgetState>();
    final range = await showDialog<DashboardRange>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.dashboardShows),
        children: [
          for (final r in DashboardRange.values)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(r),
              child: Text(_rangeLabel(l10n, r)),
            ),
        ],
      ),
    );
    if (range == null || !mounted) return;
    DateTimeRange? custom;
    if (range == DashboardRange.custom) {
      final now = DateTime.now();
      custom = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: DateTime(now.year + 2),
        initialDateRange: settings.customRange,
      );
      if (custom == null) return;
    }
    await settings.setDashboardRange(range, custom: custom);
    await state.refresh();
  }

  String _rangeLabel(AppLocalizations l10n, DashboardRange r) => switch (r) {
    DashboardRange.month => l10n.rangeMonth,
    DashboardRange.period => l10n.rangePeriod,
    DashboardRange.custom => l10n.rangeCustom,
  };

  Future<void> _setName() async {
    final l10n = AppLocalizations.of(context);
    final state = context.read<BudgetState>();
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.yourName),
        content: TextField(
          controller: name,
          autofocus: true,
          decoration: InputDecoration(helperText: l10n.yourNameHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    final text = name.text.trim();
    name.dispose();
    if (ok != true || !mounted) return;
    await attemptMoney(
      context,
      () => state.change((repo) => repo.setName(text.isEmpty ? null : text)),
    );
  }

  /// F04: confirmed by typing the address; refused while the user owes a
  /// household.
  Future<void> _deleteAccount() async {
    final l10n = AppLocalizations.of(context);
    final state = context.read<BudgetState>();
    final auth = context.read<AuthState>();
    final email = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccount),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.deleteAccountBody),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(labelText: l10n.email),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.deleteAccount),
          ),
        ],
      ),
    );
    final typed = email.text.trim();
    email.dispose();
    if (ok != true || !mounted) return;
    final deleted = await attemptMoney(
      context,
      () => state.repository.deleteAccount(typed),
    );
    if (deleted) await auth.signOut();
  }

  Future<void> _signOut() async {
    final l10n = AppLocalizations.of(context);
    final auth = context.read<AuthState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.signOut),
        content: Text(l10n.signOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.signOut),
          ),
        ],
      ),
    );
    // the app closes this screen once the user is signed out
    if (confirmed == true) {
      await signOutOfGoogle();
      await auth.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<AppSettings>();

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settings)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // ---- Appearance ----
          _SectionHeader(l10n.appearance),
          _Group(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.theme,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<ThemeMode>(
                        segments: [
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text(l10n.themeDark),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text(l10n.themeLight),
                          ),
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text(l10n.themeAuto),
                          ),
                        ],
                        selected: {settings.themeMode},
                        showSelectedIcon: false,
                        onSelectionChanged: (s) =>
                            settings.setThemeMode(s.first),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ---- The dashboard ----
          _SectionHeader(l10n.general),
          _Group(
            children: [
              ListTile(
                leading: const Icon(Icons.date_range_outlined),
                title: Text(l10n.dashboardShows),
                subtitle: Text(_rangeLabel(l10n, settings.dashboardRange)),
                onTap: () => _pickRange(settings),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: Text(l10n.wallet),
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const WalletScreen())),
              ),
            ],
          ),

          // ---- Account ----
          _SectionHeader(l10n.account),
          _Group(
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(
                  l10n.signedInAs(context.watch<AuthState>().email ?? ''),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: Text(l10n.yourName),
                onTap: _setName,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout),
                title: Text(l10n.signOut),
                onTap: _signOut,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.person_remove_outlined),
                title: Text(l10n.deleteAccount),
                onTap: _deleteAccount,
              ),
            ],
          ),

          // ---- Security ----
          _SectionHeader(l10n.security),
          _Group(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.lock_outline),
                title: Text(l10n.appLock),
                subtitle: Text(l10n.appLockSubtitle),
                value: _hasPin,
                onChanged: _toggleLock,
              ),
              if (_hasPin) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.pin_outlined),
                  title: Text(l10n.changePin),
                  onTap: _changePin,
                ),
              ],
              if (_hasPin && _biometricAvailable) ...[
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint),
                  title: Text(l10n.biometricUnlock),
                  value: _biometricEnabled,
                  onChanged: _toggleBiometric,
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),
          _Group(
            children: [
              ListTile(
                title: Text(l10n.about),
                trailing: Text(
                  'v1.0.0',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// A card that groups related rows, like the design's rounded sections.
class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _PinSetupDialog extends StatefulWidget {
  const _PinSetupDialog();

  @override
  State<_PinSetupDialog> createState() => _PinSetupDialogState();
}

class _PinSetupDialogState extends State<_PinSetupDialog> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    final pin = _pinController.text;
    if (pin.length < 6) {
      setState(() => _error = l10n.pinTooShort);
      return;
    }
    if (pin != _confirmController.text) {
      setState(() => _error = l10n.pinsDontMatch);
      return;
    }
    Navigator.of(context).pop(pin);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.setPin),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pinController,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.enterPin,
              counterText: '',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmController,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: l10n.confirmPin,
              errorText: _error,
              counterText: '',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _submit, child: Text(l10n.save)),
      ],
    );
  }
}
